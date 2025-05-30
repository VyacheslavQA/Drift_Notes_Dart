// Путь: lib/widgets/bite_activity_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../models/weather_api_model.dart';
import '../models/bite_forecast_model.dart';
import '../localization/app_localizations.dart';

/// Улучшенный виджет для отображения активности клева по времени суток
class BiteActivityChart extends StatefulWidget {
  final Map<String, dynamic>? fishingForecast;
  final WeatherApiResponse? weatherData;
  final double height;
  final bool showTitle;
  final bool showLegend;
  final bool isInteractive;
  final String? selectedFishingType;
  final Function(String)? onFishingTypeChanged;

  const BiteActivityChart({
    super.key,
    this.fishingForecast,
    this.weatherData,
    this.height = 300,
    this.showTitle = true,
    this.showLegend = true,
    this.isInteractive = true,
    this.selectedFishingType,
    this.onFishingTypeChanged,
  });

  @override
  State<BiteActivityChart> createState() => _BiteActivityChartState();
}

class _BiteActivityChartState extends State<BiteActivityChart>
    with TickerProviderStateMixin {
  List<FlSpot> _activitySpots = [];
  List<FlSpot> _pressureSpots = [];
  List<FlSpot> _temperatureSpots = [];
  List<String> _timeLabels = [];
  List<BiteWindow> _biteWindows = [];
  List<WeatherPoint> _weatherPoints = [];
  int? _touchedIndex;
  String _selectedFishingType = 'spinning';

  // Данные для астрономии
  double? _sunriseHour;
  double? _sunsetHour;

  // Анимации
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _animationValue;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedFishingType = widget.selectedFishingType ?? 'spinning';
    _setupAnimations();
    _generateEnhancedBiteActivityData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BiteActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFishingType != widget.selectedFishingType ||
        oldWidget.fishingForecast != widget.fishingForecast ||
        oldWidget.weatherData != widget.weatherData) {
      _selectedFishingType = widget.selectedFishingType ?? _selectedFishingType;
      _generateEnhancedBiteActivityData();
    }
  }

  void _generateEnhancedBiteActivityData() {
    _activitySpots.clear();
    _pressureSpots.clear();
    _temperatureSpots.clear();
    _timeLabels.clear();
    _biteWindows.clear();
    _weatherPoints.clear();

    // Получаем данные астрономии
    if (widget.weatherData?.forecast.isNotEmpty == true) {
      final astro = widget.weatherData!.forecast.first.astro;
      _sunriseHour = _parseTimeToHour(astro.sunrise);
      _sunsetHour = _parseTimeToHour(astro.sunset);
    }

    // Генерируем данные активности клева на 24 часа с учетом типа рыбалки
    for (int hour = 0; hour < 24; hour++) {
      final activity = _calculateAdvancedHourlyBiteActivity(hour);
      final pressure = _calculateHourlyPressure(hour);
      final temperature = _calculateHourlyTemperature(hour);

      _activitySpots.add(FlSpot(hour.toDouble(), activity));
      _pressureSpots.add(FlSpot(hour.toDouble(), pressure));
      _temperatureSpots.add(FlSpot(hour.toDouble(), temperature));
      _timeLabels.add('${hour.toString().padLeft(2, '0')}:00');

      // Добавляем погодные точки
      if (hour % 3 == 0) {
        _weatherPoints.add(WeatherPoint(
          hour: hour,
          temperature: temperature,
          weatherIcon: _getHourlyWeatherIcon(hour),
          windSpeed: _getHourlyWindSpeed(hour),
          precipitation: _getHourlyPrecipitation(hour),
        ));
      }
    }

    // Определяем оптимальные окна для рыбалки с учетом типа
    _identifyEnhancedBiteWindows();

    if (mounted) {
      setState(() {});
    }
  }

  /// Расчет активности клева с учетом типа рыбалки
  double _calculateAdvancedHourlyBiteActivity(int hour) {
    double baseActivity = 0.2;

    // Базовые пики активности (универсальные)
    if (hour >= 5 && hour <= 9) {
      final morningPeak = 6.5;
      final distance = (hour - morningPeak).abs();
      baseActivity = 0.85 - (distance * 0.15);
    } else if (hour >= 17 && hour <= 21) {
      final eveningPeak = 19.0;
      final distance = (hour - eveningPeak).abs();
      baseActivity = 0.9 - (distance * 0.12);
    } else if (hour >= 10 && hour <= 16) {
      baseActivity = 0.45 + math.sin((hour - 13) * 0.3) * 0.1;
    } else {
      baseActivity = 0.15 + math.sin(hour * 0.2) * 0.05;
    }

    // Корректировки по типу рыбалки
    baseActivity = _applyFishingTypeModifiers(baseActivity, hour);

    // Корректировка по погодным условиям
    if (widget.fishingForecast != null) {
      baseActivity = _applyWeatherModifiers(baseActivity);
    }

    // Корректировки по времени относительно восхода/заката
    baseActivity = _applySolarModifiers(baseActivity, hour);

    return baseActivity.clamp(0.0, 1.0);
  }

  double _applyFishingTypeModifiers(double baseActivity, int hour) {
    switch (_selectedFishingType) {
      case 'carp_fishing':
      // Карп активнее ночью и ранним утром
        if (hour >= 22 || hour <= 6) baseActivity *= 1.3;
        if (hour >= 7 && hour <= 9) baseActivity *= 1.2;
        if (hour >= 12 && hour <= 16) baseActivity *= 0.7; // Менее активен днем
        break;

      case 'feeder':
      // Фидер эффективнее утром и вечером
        if (hour >= 5 && hour <= 10) baseActivity *= 1.2;
        if (hour >= 17 && hour <= 22) baseActivity *= 1.25;
        if (hour >= 11 && hour <= 16) baseActivity *= 0.8;
        break;

      case 'float_fishing':
      // Поплавочная ловля лучше в спокойное время
        if (hour >= 6 && hour <= 11) baseActivity *= 1.15;
        if (hour >= 16 && hour <= 20) baseActivity *= 1.1;
        break;

      case 'ice_fishing':
      // Зимняя рыбалка - свои особенности
        if (hour >= 8 && hour <= 14) baseActivity *= 1.2; // Дневная активность
        if (hour >= 15 && hour <= 17) baseActivity *= 1.1; // Вечерний клев
        if (hour >= 22 || hour <= 5) baseActivity *= 0.6; // Ночью хуже
        break;

      case 'spinning':
      default:
      // Спиннинг - классические утренние и вечерние пики
        if (hour >= 5 && hour <= 9) baseActivity *= 1.15;
        if (hour >= 18 && hour <= 21) baseActivity *= 1.2;
        break;
    }

    return baseActivity;
  }

  double _applyWeatherModifiers(double baseActivity) {
    final factors = widget.fishingForecast!['factors'] as Map<String, dynamic>?;
    if (factors != null) {
      // Учитываем давление
      final pressure = factors['pressure']?['value'] as double?;
      if (pressure != null) {
        if (pressure > 0.7) {
          baseActivity *= 1.15;
        } else if (pressure < 0.4) {
          baseActivity *= 0.8;
        }
      }

      // Учитываем ветер с поправкой на тип рыбалки
      final wind = factors['wind']?['value'] as double?;
      if (wind != null) {
        if (_selectedFishingType == 'ice_fishing') {
          // На зимней рыбалке ветер менее критичен
          baseActivity *= (0.95 + wind * 0.1);
        } else if (_selectedFishingType == 'carp_fishing') {
          // Карп любит легкий ветерок
          if (wind > 0.4 && wind < 0.8) baseActivity *= 1.15;
        } else {
          // Для остальных типов
          if (wind > 0.6) {
            baseActivity *= 1.1;
          } else if (wind < 0.3) {
            baseActivity *= 0.85;
          }
        }
      }

      // Учитываем фазу луны
      final moon = factors['moon']?['value'] as double?;
      if (moon != null) {
        if (_selectedFishingType == 'carp_fishing') {
          // Карп особенно чувствителен к луне
          baseActivity *= (0.85 + moon * 0.3);
        } else {
          baseActivity *= (0.9 + moon * 0.2);
        }
      }
    }

    return baseActivity;
  }

  double _applySolarModifiers(double baseActivity, int hour) {
    if (_sunriseHour != null && _sunsetHour != null) {
      final hourDiff = (hour - _sunriseHour!).abs();
      if (hourDiff <= 2) {
        baseActivity *= 1.2;
      }

      final sunsetDiff = (hour - _sunsetHour!).abs();
      if (sunsetDiff <= 2) {
        baseActivity *= 1.25;
      }
    }

    return baseActivity;
  }

  double _calculateHourlyPressure(int hour) {
    final basePressure = widget.weatherData?.current.pressureMb ?? 1013.25;
    final variation = math.sin(hour * math.pi / 12) * 5 + math.cos(hour * math.pi / 8) * 3;
    return ((basePressure + variation) / 1.333).clamp(740.0, 780.0); // В мм рт.ст.
  }

  double _calculateHourlyTemperature(int hour) {
    final baseTemp = widget.weatherData?.current.tempC ?? 15.0;
    final dailyVariation = math.sin((hour - 14) * math.pi / 12) * 8;
    return (baseTemp + dailyVariation).clamp(-30.0, 40.0);
  }

  IconData _getHourlyWeatherIcon(int hour) {
    // Упрощенная логика для демонстрации
    if (hour >= 6 && hour <= 18) {
      return Icons.wb_sunny;
    } else if (hour >= 19 && hour <= 21) {
      return Icons.cloud;
    }
    return Icons.nights_stay;
  }

  double _getHourlyWindSpeed(int hour) {
    final baseWind = widget.weatherData?.current.windKph ?? 10.0;
    final variation = math.sin(hour * math.pi / 8) * 5;
    return (baseWind + variation).clamp(0.0, 30.0);
  }

  double _getHourlyPrecipitation(int hour) {
    // Упрощенная логика
    if (hour >= 14 && hour <= 18) return 20.0;
    if (hour >= 2 && hour <= 6) return 10.0;
    return 0.0;
  }

  void _identifyEnhancedBiteWindows() {
    List<BiteWindow> windows = [];
    int? windowStart;

    for (int i = 0; i < _activitySpots.length; i++) {
      final activity = _activitySpots[i].y;

      if (activity > 0.6 && windowStart == null) {
        windowStart = i;
      } else if (activity <= 0.6 && windowStart != null) {
        windows.add(BiteWindow(
          startHour: windowStart,
          endHour: i - 1,
          averageActivity: _calculateAverageActivity(windowStart, i - 1),
          type: _getWindowType(windowStart),
          fishingType: _selectedFishingType,
          recommendations: _getWindowRecommendations(windowStart, i - 1),
        ));
        windowStart = null;
      }
    }

    if (windowStart != null) {
      windows.add(BiteWindow(
        startHour: windowStart,
        endHour: 23,
        averageActivity: _calculateAverageActivity(windowStart, 23),
        type: _getWindowType(windowStart),
        fishingType: _selectedFishingType,
        recommendations: _getWindowRecommendations(windowStart, 23),
      ));
    }

    _biteWindows = windows;
  }

  List<String> _getWindowRecommendations(int startHour, int endHour) {
    List<String> recommendations = [];

    switch (_selectedFishingType) {
      case 'carp_fishing':
        if (startHour >= 22 || startHour <= 6) {
          recommendations.addAll(['Бойлы с аттрактантом', 'Крупные кормушки', 'Донные оснастки']);
        } else {
          recommendations.addAll(['ПВА-пакеты', 'Поп-апы', 'Метод кормушки']);
        }
        break;

      case 'feeder':
        recommendations.addAll(['Опарыш + мотыль', 'Сыпучие прикормки', 'Тонкие поводки']);
        if (startHour >= 17) {
          recommendations.add('Светящиеся сигнализаторы');
        }
        break;

      case 'float_fishing':
        recommendations.addAll(['Живые насадки', 'Легкие поплавки', 'Прозрачная леска']);
        break;

      case 'spinning':
        if (startHour >= 5 && startHour <= 9) {
          recommendations.addAll(['Воблеры яркие', 'Поверхностные приманки', 'Быстрая проводка']);
        } else {
          recommendations.addAll(['Джиг головки', 'Силикон', 'Ступенчатая проводка']);
        }
        break;

      case 'ice_fishing':
        recommendations.addAll(['Мормышки с насадкой', 'Балансиры', 'Активная игра']);
        break;

      default:
        recommendations.addAll(['Универсальные приманки', 'Средняя активность', 'Пробуйте разное']);
    }

    return recommendations;
  }

  double _calculateAverageActivity(int start, int end) {
    double sum = 0;
    int count = 0;
    for (int i = start; i <= end && i < _activitySpots.length; i++) {
      sum += _activitySpots[i].y;
      count++;
    }
    return count > 0 ? sum / count : 0;
  }

  BiteWindowType _getWindowType(int startHour) {
    if (startHour >= 5 && startHour <= 9) return BiteWindowType.morning;
    if (startHour >= 17 && startHour <= 21) return BiteWindowType.evening;
    if (startHour >= 10 && startHour <= 16) return BiteWindowType.day;
    return BiteWindowType.night;
  }

  double? _parseTimeToHour(String timeStr) {
    try {
      final cleanTime = timeStr.trim().toLowerCase();
      final parts = cleanTime.split(':');

      if (parts.length >= 2) {
        final hourPart = parts[0];
        final minuteAndPeriod = parts[1].split(' ');

        var hour = int.tryParse(hourPart) ?? 0;
        final minute = int.tryParse(minuteAndPeriod[0]) ?? 0;

        if (minuteAndPeriod.length > 1) {
          final period = minuteAndPeriod[1];
          if (period == 'pm' && hour != 12) {
            hour += 12;
          } else if (period == 'am' && hour == 12) {
            hour = 0;
          }
        }

        return hour + (minute / 60.0);
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга времени "$timeStr": $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_activitySpots.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            localizations.translate('no_data_to_display'),
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            _buildEnhancedChartHeader(localizations),
            const SizedBox(height: 16),
          ],

          Expanded(child: _buildEnhancedChart()),

          if (widget.showLegend) ...[
            const SizedBox(height: 12),
            _buildEnhancedLegend(localizations),
          ],

          if (_biteWindows.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildOptimalWindows(localizations),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedChartHeader(AppLocalizations localizations) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('bite_activity'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getFishingTypeDisplayName(_selectedFishingType),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onFishingTypeChanged != null)
              _buildFishingTypeSelector(),
          ],
        ),
      ],
    );
  }

  Widget _buildFishingTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFishingType,
          isDense: true,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 12,
          ),
          dropdownColor: AppConstants.surfaceColor,
          items: [
            DropdownMenuItem(value: 'spinning', child: Text('🎣 Спиннинг')),
            DropdownMenuItem(value: 'carp_fishing', child: Text('🐟 Карп')),
            DropdownMenuItem(value: 'feeder', child: Text('🎯 Фидер')),
            DropdownMenuItem(value: 'float_fishing', child: Text('🎈 Поплавок')),
            DropdownMenuItem(value: 'ice_fishing', child: Text('❄️ Зимняя')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFishingType = value;
              });
              widget.onFishingTypeChanged?.call(value);
              _generateEnhancedBiteActivityData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedChart() {
    return AnimatedBuilder(
      animation: _animationValue,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 0.2,
              verticalInterval: 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppConstants.textColor.withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: AppConstants.textColor.withValues(alpha: 0.05),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 0.25,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 3,
                  getTitlesWidget: (value, meta) {
                    final hour = value.toInt();
                    if (hour >= 0 && hour < 24 && hour % 3 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              _buildPressureBackgroundLine(),
              _buildMainActivityLine(),
            ],
            extraLinesData: _buildEnhancedExtraLines(),
            lineTouchData: widget.isInteractive ? _buildEnhancedTouchData() : LineTouchData(enabled: false),
            minY: 0,
            maxY: 1,
          ),
        );
      },
    );
  }

  LineChartBarData _buildPressureBackgroundLine() {
    // Нормализуем давление для отображения на том же графике
    final normalizedPressureSpots = _pressureSpots.map((spot) {
      final normalizedPressure = (spot.y - 740) / 40; // Приводим к диапазону 0-1
      return FlSpot(spot.x, normalizedPressure.clamp(0.0, 1.0));
    }).toList();

    return LineChartBarData(
      spots: normalizedPressureSpots,
      isCurved: true,
      color: Colors.grey.withValues(alpha: 0.3),
      barWidth: 1,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.grey.withValues(alpha: 0.1),
      ),
    );
  }

  LineChartBarData _buildMainActivityLine() {
    final animatedSpots = _activitySpots.map((spot) {
      return FlSpot(spot.x, spot.y * _animationValue.value);
    }).toList();

    return LineChartBarData(
      spots: animatedSpots,
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          const Color(0xFF4CAF50),
          const Color(0xFF8BC34A),
          const Color(0xFFFFC107),
          const Color(0xFFFF9800),
          const Color(0xFFF44336),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final activity = _activitySpots[index].y;
          final isPeak = activity > 0.8;

          return FlDotCirclePainter(
            radius: isPeak && _touchedIndex == index ? 8 : (isPeak ? 6 : 3),
            color: _getActivityColor(activity),
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.3),
            const Color(0xFF8BC34A).withValues(alpha: 0.2),
            const Color(0xFFFFC107).withValues(alpha: 0.15),
            const Color(0xFFFF9800).withValues(alpha: 0.1),
            const Color(0xFFF44336).withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }

  ExtraLinesData _buildEnhancedExtraLines() {
    final lines = <VerticalLine>[];

    // Восход солнца
    if (_sunriseHour != null) {
      lines.add(
        VerticalLine(
          x: _sunriseHour!,
          color: Colors.orange.withValues(alpha: 0.8),
          strokeWidth: 2,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            labelResolver: (line) => '🌅',
            style: const TextStyle(fontSize: 16),
            alignment: Alignment.topCenter,
          ),
        ),
      );
    }

    // Закат солнца
    if (_sunsetHour != null) {
      lines.add(
        VerticalLine(
          x: _sunsetHour!,
          color: Colors.deepPurple.withValues(alpha: 0.8),
          strokeWidth: 2,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            labelResolver: (line) => '🌇',
            style: const TextStyle(fontSize: 16),
            alignment: Alignment.topCenter,
          ),
        ),
      );
    }

    // Добавляем вертикальные линии для пиковых периодов
    for (final window in _biteWindows) {
      if (window.averageActivity > 0.7) {
        lines.add(
          VerticalLine(
            x: window.startHour.toDouble(),
            color: _getActivityColor(window.averageActivity).withValues(alpha: 0.3),
            strokeWidth: 3,
            dashArray: [2, 2],
          ),
        );
      }
    }

    return ExtraLinesData(verticalLines: lines);
  }

  LineTouchData _buildEnhancedTouchData() {
    final localizations = AppLocalizations.of(context);

    return LineTouchData(
      enabled: true,
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        if (response != null && response.lineBarSpots != null) {
          setState(() {
            _touchedIndex = response.lineBarSpots!.first.spotIndex;
          });
        } else {
          setState(() {
            _touchedIndex = null;
          });
        }
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => AppConstants.surfaceColor.withValues(alpha: 0.95),
        tooltipBorder: BorderSide(
          color: AppConstants.primaryColor.withValues(alpha: 0.5),
          width: 1,
        ),
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.all(12),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final hour = spot.x.toInt();
            final activity = spot.y;
            final activityPercent = (activity * 100).round();
            final timeStr = '${hour.toString().padLeft(2, '0')}:00';

            // Получаем дополнительную информацию для этого часа
            final pressure = _pressureSpots.isNotEmpty && hour < _pressureSpots.length
                ? _pressureSpots[hour].y.round()
                : 0;
            final temperature = _temperatureSpots.isNotEmpty && hour < _temperatureSpots.length
                ? _temperatureSpots[hour].y.round()
                : 0;

            final recommendations = _getHourlyRecommendations(hour, activity);

            return LineTooltipItem(
              '$timeStr\n'
                  '${localizations.translate('bite_probability')}: $activityPercent%\n'
                  '${_getActivityDescription(activity)}\n'
                  'Давление: $pressure мм\n'
                  'Температура: $temperature°C\n'
                  '💡 $recommendations',
              TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.3,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  String _getHourlyRecommendations(int hour, double activity) {
    if (activity > 0.8) {
      switch (_selectedFishingType) {
        case 'carp_fishing':
          return hour >= 22 || hour <= 6 ? 'Бойлы + PVA' : 'Метод кормушки';
        case 'feeder':
          return 'Опарыш + мотыль';
        case 'spinning':
          return hour <= 10 ? 'Воблеры' : 'Джиг';
        default:
          return 'Активные приманки';
      }
    } else if (activity > 0.6) {
      return 'Средняя активность';
    } else {
      return 'Пассивная рыба';
    }
  }

  Widget _buildEnhancedLegend(AppLocalizations localizations) {
    return Column(
      children: [
        // Основная легенда активности
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildLegendItem(
              color: const Color(0xFF4CAF50),
              label: localizations.translate('excellent'),
              range: '80-100%',
            ),
            _buildLegendItem(
              color: const Color(0xFF8BC34A),
              label: localizations.translate('good'),
              range: '60-80%',
            ),
            _buildLegendItem(
              color: const Color(0xFFFFC107),
              label: localizations.translate('moderate'),
              range: '40-60%',
            ),
            _buildLegendItem(
              color: const Color(0xFFFF9800),
              label: localizations.translate('poor'),
              range: '20-40%',
            ),
            _buildLegendItem(
              color: const Color(0xFFF44336),
              label: localizations.translate('very_poor_activity'),
              range: '0-20%',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Дополнительная информация
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendSymbol('🌅', 'Восход'),
            _buildLegendSymbol('🌇', 'Закат'),
            _buildLegendSymbol('📊', 'Давление (фон)'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String range,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($range)',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendSymbol(String symbol, String description) {
    return Column(
      children: [
        Text(
          symbol,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          description,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalWindows(AppLocalizations localizations) {
    if (_biteWindows.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('optimal_time_windows'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _biteWindows.map((window) => _buildEnhancedWindowChip(window)).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedWindowChip(BiteWindow window) {
    final color = _getActivityColor(window.averageActivity);
    final timeRange = '${window.startHour.toString().padLeft(2, '0')}:00-${window.endHour.toString().padLeft(2, '0')}:00';

    return GestureDetector(
      onTap: () => _showWindowDetails(window),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeRange,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${(window.averageActivity * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWindowDetails(BiteWindow window) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Оптимальное время: ${window.startHour.toString().padLeft(2, '0')}:00-${window.endHour.toString().padLeft(2, '0')}:00',
          style: TextStyle(color: AppConstants.textColor, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Активность: ${(window.averageActivity * 100).round()}%',
              style: TextStyle(
                color: _getActivityColor(window.averageActivity),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Рекомендации для ${_getFishingTypeDisplayName(window.fishingType)}:',
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...window.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('• ', style: TextStyle(color: Colors.amber)),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(color: AppConstants.textColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
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

  String _getFishingTypeDisplayName(String type) {
    switch (type) {
      case 'carp_fishing': return 'Карповая рыбалка';
      case 'spinning': return 'Спиннинг';
      case 'feeder': return 'Фидер';
      case 'float_fishing': return 'Поплавочная';
      case 'ice_fishing': return 'Зимняя рыбалка';
      default: return 'Рыбалка';
    }
  }

  Color _getActivityColor(double activity) {
    if (activity > 0.8) return const Color(0xFF4CAF50);
    if (activity > 0.6) return const Color(0xFF8BC34A);
    if (activity > 0.4) return const Color(0xFFFFC107);
    if (activity > 0.2) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getActivityDescription(double activity) {
    final localizations = AppLocalizations.of(context);
    if (activity > 0.8) return localizations.translate('excellent_fishing_conditions');
    if (activity > 0.6) return localizations.translate('good_fishing_conditions');
    if (activity > 0.4) return localizations.translate('average_fishing_conditions');
    if (activity > 0.2) return localizations.translate('poor_fishing_conditions');
    return localizations.translate('bad_fishing_conditions');
  }
}

/// Расширенная модель временного окна высокой активности клева
class BiteWindow {
  final int startHour;
  final int endHour;
  final double averageActivity;
  final BiteWindowType type;
  final String fishingType;
  final List<String> recommendations;

  BiteWindow({
    required this.startHour,
    required this.endHour,
    required this.averageActivity,
    required this.type,
    required this.fishingType,
    required this.recommendations,
  });
}

enum BiteWindowType {
  morning,
  day,
  evening,
  night,
}

/// Модель погодной точки для отображения на графике
class WeatherPoint {
  final int hour;
  final double temperature;
  final IconData weatherIcon;
  final double windSpeed;
  final double precipitation;

  WeatherPoint({
    required this.hour,
    required this.temperature,
    required this.weatherIcon,
    required this.windSpeed,
    required this.precipitation,
  });
}