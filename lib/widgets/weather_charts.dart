// Путь: lib/widgets/weather_charts.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../models/weather_api_model.dart';
import '../localization/app_localizations.dart';

/// Виджет графика атмосферного давления за 24 часа
class PressureChart extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final double height;

  const PressureChart({
    super.key,
    required this.weatherData,
    this.height = 200,
  });

  @override
  State<PressureChart> createState() => _PressureChartState();
}

class _PressureChartState extends State<PressureChart> {
  int? touchedIndex;
  List<FlSpot> pressureSpots = [];
  List<String> timeLabels = [];
  double minPressure = 0;
  double maxPressure = 0;

  @override
  void initState() {
    super.initState();
    _generatePressureData();
  }

  void _generatePressureData() {
    pressureSpots.clear();
    timeLabels.clear();

    if (widget.weatherData.forecast.isNotEmpty) {
      final hours = widget.weatherData.forecast.first.hour;
      final now = DateTime.now();

      // Берем данные за последние 12 часов и следующие 12 часов
      final relevantHours =
          hours.where((hour) {
            final hourTime = DateTime.parse(hour.time);
            return hourTime.isAfter(now.subtract(const Duration(hours: 12))) &&
                hourTime.isBefore(now.add(const Duration(hours: 12)));
          }).toList();

      if (relevantHours.isNotEmpty) {
        // Генерируем реалистичные данные давления
        final basePressure = widget.weatherData.current.pressureMb;

        for (int i = 0; i < relevantHours.length; i++) {
          final hour = relevantHours[i];
          final hourTime = DateTime.parse(hour.time);

          // Имитируем изменения давления (в реальном приложении данные придут с API)
          final variation = math.sin(i * 0.3) * 5 + math.cos(i * 0.2) * 3;
          final pressure = basePressure + variation;

          pressureSpots.add(FlSpot(i.toDouble(), pressure));

          // Добавляем временные метки только для каждого 3-го часа
          if (i % 3 == 0) {
            timeLabels.add(DateFormat('HH:mm').format(hourTime));
          } else {
            timeLabels.add('');
          }
        }

        if (pressureSpots.isNotEmpty) {
          minPressure =
              pressureSpots.map((spot) => spot.y).reduce(math.min) - 5;
          maxPressure =
              pressureSpots.map((spot) => spot.y).reduce(math.max) + 5;
        }
      }
    }
  }

  Color _getPressureZoneColor(double pressure) {
    if (pressure >= 1010 && pressure <= 1025) {
      return Colors.green.withValues(alpha: 0.3); // Хорошо для рыбалки
    } else if (pressure < 1000 || pressure > 1030) {
      return Colors.red.withValues(alpha: 0.3); // Плохо для рыбалки
    } else {
      return Colors.orange.withValues(alpha: 0.3); // Средне для рыбалки
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (pressureSpots.isEmpty) {
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
          // Заголовок графика
          Row(
            children: [
              Icon(Icons.speed, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('pressure_analysis'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
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
          ),

          const SizedBox(height: 16),

          // График
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
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
                      reservedSize: 45,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timeLabels[index],
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Основная линия давления
                  LineChartBarData(
                    spots: pressureSpots,
                    isCurved: true,
                    color: AppConstants.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: index == touchedIndex ? 6 : 3,
                          color: AppConstants.primaryColor,
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
                          AppConstants.primaryColor.withValues(alpha: 0.3),
                          AppConstants.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (
                    FlTouchEvent event,
                    LineTouchResponse? response,
                  ) {
                    if (response != null && response.lineBarSpots != null) {
                      setState(() {
                        touchedIndex = response.lineBarSpots!.first.spotIndex;
                      });
                    } else {
                      setState(() {
                        touchedIndex = null;
                      });
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (touchedSpot) =>
                            AppConstants.surfaceColor.withValues(alpha: 0.9),
                    tooltipBorder: BorderSide(
                      color: AppConstants.primaryColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final pressure = spot.y;
                        final pressureMmHg = (pressure / 1.333).round();

                        return LineTooltipItem(
                          '$pressureMmHg мм рт.ст.\n${pressure.toInt()} гПа',
                          TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: minPressure,
                maxY: maxPressure,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Легенда
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                color: Colors.green,
                label: localizations.translate('excellent'),
                description: '1010-1025 гПа',
              ),
              _buildLegendItem(
                color: Colors.orange,
                label: localizations.translate('moderate'),
                description: '1000-1010 гПа',
              ),
              _buildLegendItem(
                color: Colors.red,
                label: localizations.translate('poor'),
                description: '<1000 >1030 гПа',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
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
}

/// Комбинированный график температуры, ветра и осадков
class CombinedWeatherChart extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final double height;

  const CombinedWeatherChart({
    super.key,
    required this.weatherData,
    this.height = 250,
  });

  @override
  State<CombinedWeatherChart> createState() => _CombinedWeatherChartState();
}

class _CombinedWeatherChartState extends State<CombinedWeatherChart> {
  List<FlSpot> temperatureSpots = [];
  List<FlSpot> windSpots = [];
  List<FlSpot> rainSpots = [];
  List<String> timeLabels = [];
  int selectedChart = 0; // 0 - все, 1 - температура, 2 - ветер, 3 - дождь

  @override
  void initState() {
    super.initState();
    _generateCombinedData();
  }

  void _generateCombinedData() {
    temperatureSpots.clear();
    windSpots.clear();
    rainSpots.clear();
    timeLabels.clear();

    if (widget.weatherData.forecast.isNotEmpty) {
      final hours = widget.weatherData.forecast.first.hour;
      final now = DateTime.now();

      final relevantHours =
          hours.where((hour) {
            final hourTime = DateTime.parse(hour.time);
            return hourTime.isAfter(now) &&
                hourTime.isBefore(now.add(const Duration(hours: 24)));
          }).toList();

      for (int i = 0; i < relevantHours.length; i++) {
        final hour = relevantHours[i];
        final hourTime = DateTime.parse(hour.time);

        temperatureSpots.add(FlSpot(i.toDouble(), hour.tempC));
        windSpots.add(FlSpot(i.toDouble(), hour.windKph / 3.6)); // м/с
        rainSpots.add(FlSpot(i.toDouble(), hour.chanceOfRain.toDouble()));

        if (i % 3 == 0) {
          timeLabels.add(DateFormat('HH:mm').format(hourTime));
        } else {
          timeLabels.add('');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
          // Заголовок и переключатели
          Row(
            children: [
              Icon(Icons.analytics, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('weather_factors'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildChartToggle(),
            ],
          ),

          const SizedBox(height: 16),

          // График
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getGridInterval(),
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
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatLeftTitle(value),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timeLabels[index],
                              style: TextStyle(
                                color: AppConstants.textColor.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _getLineBarsData(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (touchedSpot) =>
                            AppConstants.surfaceColor.withValues(alpha: 0.9),
                    tooltipBorder: BorderSide(
                      color: AppConstants.primaryColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          _formatTooltip(spot),
                          TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: _getMinY(),
                maxY: _getMaxY(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Легенда
          _buildCombinedLegend(),
        ],
      ),
    );
  }

  Widget _buildChartToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Все', 0),
          _buildToggleButton('T°', 1),
          _buildToggleButton('💨', 2),
          _buildToggleButton('🌧', 3),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    final isSelected = selectedChart == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChart = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _getLineBarsData() {
    List<LineChartBarData> bars = [];

    if (selectedChart == 0 || selectedChart == 1) {
      // Температура
      bars.add(
        LineChartBarData(
          spots: temperatureSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (selectedChart == 0 || selectedChart == 2) {
      // Ветер (нормализованный для отображения)
      bars.add(
        LineChartBarData(
          spots:
              windSpots
                  .map((spot) => FlSpot(spot.x, spot.y * 2))
                  .toList(), // Умножаем для видимости
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    if (selectedChart == 0 || selectedChart == 3) {
      // Дождь (нормализованный)
      bars.add(
        LineChartBarData(
          spots:
              rainSpots
                  .map((spot) => FlSpot(spot.x, spot.y / 5))
                  .toList(), // Делим для масштаба
          isCurved: false,
          color: Colors.lightBlue,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return bars;
  }

  double _getGridInterval() {
    switch (selectedChart) {
      case 1:
        return 5; // Температура
      case 2:
        return 2; // Ветер
      case 3:
        return 5; // Дождь
      default:
        return 5; // Все
    }
  }

  String _formatLeftTitle(double value) {
    switch (selectedChart) {
      case 1:
        return '${value.toInt()}°C';
      case 2:
        return '${(value / 2).toInt()}м/с';
      case 3:
        return '${(value * 5).toInt()}%';
      default:
        return value.toInt().toString();
    }
  }

  String _formatTooltip(LineBarSpot spot) {
    final index = spot.x.toInt();
    if (index < 0 || index >= temperatureSpots.length) return '';

    final temp = temperatureSpots[index].y;
    final wind = windSpots[index].y;
    final rain = rainSpots[index].y;

    return 'T: ${temp.round()}°C\nВетер: ${wind.round()}м/с\nДождь: ${rain.round()}%';
  }

  double _getMinY() {
    switch (selectedChart) {
      case 1: // Температура
        return temperatureSpots.map((spot) => spot.y).reduce(math.min) - 5;
      case 2: // Ветер (нормализованный)
        return 0;
      case 3: // Дождь (нормализованный)
        return 0;
      default: // Все
        return -10;
    }
  }

  double _getMaxY() {
    switch (selectedChart) {
      case 1: // Температура
        return temperatureSpots.map((spot) => spot.y).reduce(math.max) + 5;
      case 2: // Ветер (нормализованный)
        return windSpots.map((spot) => spot.y * 2).reduce(math.max) + 5;
      case 3: // Дождь (нормализованный)
        return 20; // 100% / 5
      default: // Все
        return 40;
    }
  }

  Widget _buildCombinedLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (selectedChart == 0 || selectedChart == 1)
          _buildLegendItem(color: Colors.red, label: 'Температура', unit: '°C'),
        if (selectedChart == 0 || selectedChart == 2)
          _buildLegendItem(color: Colors.blue, label: 'Ветер', unit: 'м/с'),
        if (selectedChart == 0 || selectedChart == 3)
          _buildLegendItem(color: Colors.lightBlue, label: 'Дождь', unit: '%'),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($unit)',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
