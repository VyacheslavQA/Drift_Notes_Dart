// Путь: lib/widgets/bite_activity_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../models/weather_api_model.dart';
import '../models/bite_forecast_model.dart';
import '../localization/app_localizations.dart';

/// Специализированный виджет для отображения активности клева по времени суток
class BiteActivityChart extends StatefulWidget {
  final Map<String, dynamic>? fishingForecast;
  final WeatherApiResponse? weatherData;
  final double height;
  final bool showTitle;
  final bool showLegend;
  final bool isInteractive;

  const BiteActivityChart({
    super.key,
    this.fishingForecast,
    this.weatherData,
    this.height = 200,
    this.showTitle = true,
    this.showLegend = true,
    this.isInteractive = true,
  });

  @override
  State<BiteActivityChart> createState() => _BiteActivityChartState();
}

class _BiteActivityChartState extends State<BiteActivityChart>
    with SingleTickerProviderStateMixin {
  List<FlSpot> _activitySpots = [];
  List<String> _timeLabels = [];
  List<BiteWindow> _biteWindows = [];
  int? _touchedIndex;

  // Данные для астрономии
  double? _sunriseHour;
  double? _sunsetHour;

  // Анимация
  late AnimationController _animationController;
  late Animation<double> _animationValue;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _generateBiteActivityData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BiteActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fishingForecast != widget.fishingForecast ||
        oldWidget.weatherData != widget.weatherData) {
      _generateBiteActivityData();
    }
  }

  void _generateBiteActivityData() {
    _activitySpots.clear();
    _timeLabels.clear();
    _biteWindows.clear();

    // Получаем данные астрономии
    if (widget.weatherData?.forecast.isNotEmpty == true) {
      final astro = widget.weatherData!.forecast.first.astro;
      _sunriseHour = _parseTimeToHour(astro.sunrise);
      _sunsetHour = _parseTimeToHour(astro.sunset);
    }

    // Генерируем данные активности клева на 24 часа
    for (int hour = 0; hour < 24; hour++) {
      final activity = _calculateHourlyBiteActivity(hour);
      _activitySpots.add(FlSpot(hour.toDouble(), activity));
      _timeLabels.add('${hour.toString().padLeft(2, '0')}:00');
    }

    // Определяем оптимальные окна для рыбалки
    _identifyBiteWindows();

    if (mounted) {
      setState(() {});
    }
  }

  /// Расчет активности клева для конкретного часа
  double _calculateHourlyBiteActivity(int hour) {
    double baseActivity = 0.2; // Базовая активность

    // Пиковая активность утром и вечером ("золотые часы")
    if (hour >= 5 && hour <= 9) {
      // Утренний пик с максимумом в 6-7 утра
      final morningPeak = 6.5;
      final distance = (hour - morningPeak).abs();
      baseActivity = 0.85 - (distance * 0.15);
    } else if (hour >= 17 && hour <= 21) {
      // Вечерний пик с максимумом в 19-20 вечера
      final eveningPeak = 19.0;
      final distance = (hour - eveningPeak).abs();
      baseActivity = 0.9 - (distance * 0.12);
    } else if (hour >= 10 && hour <= 16) {
      // Дневная активность (умеренная)
      baseActivity = 0.45 + math.sin((hour - 13) * 0.3) * 0.1;
    } else {
      // Ночная активность (низкая)
      baseActivity = 0.15 + math.sin(hour * 0.2) * 0.05;
    }

    // Корректировка по погодным условиям
    if (widget.fishingForecast != null) {
      final factors = widget.fishingForecast!['factors'] as Map<String, dynamic>?;
      if (factors != null) {
        // Учитываем давление
        final pressure = factors['pressure']?['value'] as double?;
        if (pressure != null) {
          if (pressure > 0.7) {
            baseActivity *= 1.15; // Хорошее давление
          } else if (pressure < 0.4) {
            baseActivity *= 0.8; // Плохое давление
          }
        }

        // Учитываем ветер
        final wind = factors['wind']?['value'] as double?;
        if (wind != null) {
          if (wind > 0.6) {
            baseActivity *= 1.1; // Хороший ветер
          } else if (wind < 0.3) {
            baseActivity *= 0.85; // Штиль или сильный ветер
          }
        }

        // Учитываем фазу луны
        final moon = factors['moon']?['value'] as double?;
        if (moon != null) {
          baseActivity *= (0.9 + moon * 0.2); // Влияние луны 0.9-1.1
        }
      }
    }

    // Дополнительные корректировки по времени относительно восхода/заката
    if (_sunriseHour != null && _sunsetHour != null) {
      final hourDiff = (hour - _sunriseHour!).abs();
      if (hourDiff <= 2) {
        baseActivity *= 1.2; // Бонус за близость к восходу
      }

      final sunsetDiff = (hour - _sunsetHour!).abs();
      if (sunsetDiff <= 2) {
        baseActivity *= 1.25; // Бонус за близость к закату
      }
    }

    return baseActivity.clamp(0.0, 1.0);
  }

  /// Определение оптимальных временных окон для рыбалки
  void _identifyBiteWindows() {
    List<BiteWindow> windows = [];

    // Ищем периоды высокой активности (> 0.6)
    int? windowStart;

    for (int i = 0; i < _activitySpots.length; i++) {
      final activity = _activitySpots[i].y;

      if (activity > 0.6 && windowStart == null) {
        windowStart = i;
      } else if (activity <= 0.6 && windowStart != null) {
        // Конец окна
        windows.add(BiteWindow(
          startHour: windowStart,
          endHour: i - 1,
          averageActivity: _calculateAverageActivity(windowStart, i - 1),
          type: _getWindowType(windowStart),
        ));
        windowStart = null;
      }
    }

    // Если окно не закрылось в конце дня
    if (windowStart != null) {
      windows.add(BiteWindow(
        startHour: windowStart,
        endHour: 23,
        averageActivity: _calculateAverageActivity(windowStart, 23),
        type: _getWindowType(windowStart),
      ));
    }

    _biteWindows = windows;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            _buildChartHeader(localizations),
            const SizedBox(height: 16),
          ],

          Expanded(child: _buildChart()),

          if (widget.showLegend) ...[
            const SizedBox(height: 12),
            _buildLegend(localizations),
          ],

          if (_biteWindows.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildOptimalWindows(localizations),
          ],
        ],
      ),
    );
  }

  Widget _buildChartHeader(AppLocalizations localizations) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.show_chart,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                localizations.translate('hourly_bite_forecast'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '24${localizations.translate('hours')}',
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return AnimatedBuilder(
      animation: _animationValue,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.2,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppConstants.textColor.withValues(alpha: 0.1),
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
              _buildMainActivityLine(),
            ],
            extraLinesData: _buildExtraLines(),
            lineTouchData: widget.isInteractive ? _buildTouchData() : LineTouchData(enabled: false),
            minY: 0,
            maxY: 1,
          ),
        );
      },
    );
  }

  LineChartBarData _buildMainActivityLine() {
    // Создаем анимированные точки
    final animatedSpots = _activitySpots.map((spot) {
      return FlSpot(spot.x, spot.y * _animationValue.value);
    }).toList();

    return LineChartBarData(
      spots: animatedSpots,
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          const Color(0xFF4CAF50), // Зеленый (высокая активность)
          const Color(0xFF8BC34A), // Светло-зеленый
          const Color(0xFFFFC107), // Желтый (средняя активность)
          const Color(0xFFFF9800), // Оранжевый
          const Color(0xFFF44336), // Красный (низкая активность)
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final activity = _activitySpots[index].y;
          return FlDotCirclePainter(
            radius: _touchedIndex == index ? 6 : 3,
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

  ExtraLinesData _buildExtraLines() {
    final lines = <VerticalLine>[];
    final localizations = AppLocalizations.of(context);

    // Восход солнца
    if (_sunriseHour != null) {
      lines.add(
        VerticalLine(
          x: _sunriseHour!,
          color: Colors.orange.withValues(alpha: 0.6),
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
          color: Colors.deepPurple.withValues(alpha: 0.6),
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

    return ExtraLinesData(verticalLines: lines);
  }

  LineTouchData _buildTouchData() {
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
        backgroundColor: AppConstants.surfaceColor.withValues(alpha: 0.95),
        tooltipBorder: BorderSide(
          color: AppConstants.primaryColor.withValues(alpha: 0.5),
          width: 1,
        ),
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final hour = spot.x.toInt();
            final activity = spot.y;
            final activityPercent = (activity * 100).round();
            final timeStr = '${hour.toString().padLeft(2, '0')}:00';

            return LineTooltipItem(
              '$timeStr\n${localizations.translate('bite_probability')}: $activityPercent%\n${_getActivityDescription(activity)}',
              TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildLegend(AppLocalizations localizations) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
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
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
          children: _biteWindows.map((window) => _buildWindowChip(window)).toList(),
        ),
      ],
    );
  }

  Widget _buildWindowChip(BiteWindow window) {
    final color = _getActivityColor(window.averageActivity);
    final timeRange = '${window.startHour.toString().padLeft(2, '0')}:00-${window.endHour.toString().padLeft(2, '0')}:00';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
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

/// Модель временного окна высокой активности клева
class BiteWindow {
  final int startHour;
  final int endHour;
  final double averageActivity;
  final BiteWindowType type;

  BiteWindow({
    required this.startHour,
    required this.endHour,
    required this.averageActivity,
    required this.type,
  });
}

enum BiteWindowType {
  morning,
  day,
  evening,
  night,
}