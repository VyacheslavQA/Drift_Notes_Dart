// Путь: lib/screens/weather/pressure_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../localization/app_localizations.dart';

class PressureDetailScreen extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final String locationName;

  const PressureDetailScreen({
    super.key,
    required this.weatherData,
    required this.locationName,
  });

  @override
  State<PressureDetailScreen> createState() => _PressureDetailScreenState();
}

class _PressureDetailScreenState extends State<PressureDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  List<FlSpot> _pressureSpots = [];
  List<String> _timeLabels = [];
  double _minPressure = 0;
  double _maxPressure = 0;
  String _pressureTrend = 'stable';
  double _pressure24hChange = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generatePressureData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generatePressureData() {
    _pressureSpots.clear();
    _timeLabels.clear();

    final basePressure = widget.weatherData.current.pressureMb;
    final now = DateTime.now();

    // Генерируем данные за последние 24 часа с реалистичными изменениями
    for (int i = -24; i <= 0; i++) {
      final time = now.add(Duration(hours: i));

      // Имитируем естественные колебания давления
      final timeOfDay = time.hour;
      final dailyVariation = math.sin((timeOfDay - 6) * math.pi / 12) * 3; // Дневной цикл
      final randomVariation = (math.Random().nextDouble() - 0.5) * 4; // Случайные колебания
      final trendVariation = i * 0.2; // Общий тренд

      final pressure = basePressure + dailyVariation + randomVariation + trendVariation;

      _pressureSpots.add(FlSpot(i.toDouble() + 24, pressure));

      if (i % 6 == 0) {
        _timeLabels.add(DateFormat('HH:mm').format(time));
      } else {
        _timeLabels.add('');
      }
    }

    if (_pressureSpots.isNotEmpty) {
      _minPressure = _pressureSpots.map((spot) => spot.y).reduce(math.min) - 5;
      _maxPressure = _pressureSpots.map((spot) => spot.y).reduce(math.max) + 5;

      // Определяем тренд
      final firstPressure = _pressureSpots.first.y;
      final lastPressure = _pressureSpots.last.y;
      _pressure24hChange = lastPressure - firstPressure;

      if (_pressure24hChange > 2) {
        _pressureTrend = 'rising';
      } else if (_pressure24hChange < -2) {
        _pressureTrend = 'falling';
      } else {
        _pressureTrend = 'stable';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentPressure = widget.weatherData.current.pressureMb;
    final pressureMmHg = (currentPressure / 1.333).round();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('pressure_analysis'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущее давление - главная карточка
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: _buildCurrentPressureCard(pressureMmHg, currentPressure),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Тренд за 24 часа
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 1.5),
                    child: _buildTrendCard(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // График давления
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2),
                    child: _buildPressureChart(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Влияние на рыбалку
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2.5),
                    child: _buildFishingImpactCard(currentPressure),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Рекомендации
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 3),
                    child: _buildRecommendationsCard(currentPressure),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPressureCard(int pressureMmHg, double pressureMb) {
    final localizations = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withValues(alpha: 0.1),
            AppConstants.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.speed,
                  color: AppConstants.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('current_pressure'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.locationName,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Основное значение давления
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pressureMmHg.toString(),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'мм рт.ст.',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${pressureMb.toStringAsFixed(1)} гПа',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Статус давления
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getPressureStatusColor(pressureMb).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getPressureStatusColor(pressureMb).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getPressureStatus(pressureMb),
              style: TextStyle(
                color: _getPressureStatusColor(pressureMb),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            localizations.translate('pressure_trend_24h'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('trend'),
                  _getTrendText(_pressureTrend),
                  _getTrendIcon(_pressureTrend),
                  _getTrendColor(_pressureTrend),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrendItem(
                  localizations.translate('change'),
                  '${_pressure24hChange >= 0 ? '+' : ''}${_pressure24hChange.toStringAsFixed(1)} гПа',
                  _pressure24hChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  _pressure24hChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendDescription(),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendDescription() {
    final localizations = AppLocalizations.of(context);
    String description;
    Color color;

    switch (_pressureTrend) {
      case 'rising':
        description = localizations.translate('pressure_rising_description');
        color = Colors.green;
        break;
      case 'falling':
        description = localizations.translate('pressure_falling_description');
        color = Colors.red;
        break;
      default:
        description = localizations.translate('pressure_stable_description');
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureChart() {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('pressure_history_24h'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      reservedSize: 50,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
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
                      reservedSize: 25,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _timeLabels.length && _timeLabels[index].isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _timeLabels[index],
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
                  LineChartBarData(
                    spots: _pressureSpots,
                    isCurved: true,
                    color: AppConstants.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
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
                minY: _minPressure,
                maxY: _maxPressure,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingImpactCard(double pressure) {
    final localizations = AppLocalizations.of(context);
    final impact = _getFishingImpact(pressure);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: impact['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: impact['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.set_meal,
                  color: impact['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.translate('fishing_impact'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: impact['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              impact['level'],
              style: TextStyle(
                color: impact['color'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            impact['description'],
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(double pressure) {
    final localizations = AppLocalizations.of(context);
    final recommendations = _getPressureRecommendations(pressure);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('recommendations'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // Вспомогательные методы

  Color _getPressureStatusColor(double pressure) {
    if (pressure >= 1010 && pressure <= 1025) return Colors.green;
    if (pressure < 1000 || pressure > 1030) return Colors.red;
    return Colors.orange;
  }

  String _getPressureStatus(double pressure) {
    final localizations = AppLocalizations.of(context);
    if (pressure >= 1010 && pressure <= 1025) return localizations.translate('optimal_for_fishing');
    if (pressure < 1000) return localizations.translate('low_pressure');
    if (pressure > 1030) return localizations.translate('high_pressure');
    return localizations.translate('moderate_pressure');
  }

  String _getTrendText(String trend) {
    final localizations = AppLocalizations.of(context);
    switch (trend) {
      case 'rising': return localizations.translate('rising');
      case 'falling': return localizations.translate('falling');
      default: return localizations.translate('stable');
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising': return Icons.trending_up;
      case 'falling': return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising': return Colors.green;
      case 'falling': return Colors.red;
      default: return Colors.blue;
    }
  }

  Map<String, dynamic> _getFishingImpact(double pressure) {
    final localizations = AppLocalizations.of(context);

    if (pressure >= 1010 && pressure <= 1025) {
      return {
        'level': localizations.translate('excellent_for_fishing'),
        'description': localizations.translate('pressure_excellent_description'),
        'color': Colors.green,
      };
    } else if (pressure < 1000) {
      return {
        'level': localizations.translate('poor_for_fishing'),
        'description': localizations.translate('pressure_low_description'),
        'color': Colors.red,
      };
    } else if (pressure > 1030) {
      return {
        'level': localizations.translate('poor_for_fishing'),
        'description': localizations.translate('pressure_high_description'),
        'color': Colors.red,
      };
    } else {
      return {
        'level': localizations.translate('moderate_for_fishing'),
        'description': localizations.translate('pressure_moderate_description'),
        'color': Colors.orange,
      };
    }
  }

  List<String> _getPressureRecommendations(double pressure) {
    final localizations = AppLocalizations.of(context);

    if (pressure >= 1010 && pressure <= 1025) {
      return [
        localizations.translate('pressure_rec_optimal_1'),
        localizations.translate('pressure_rec_optimal_2'),
        localizations.translate('pressure_rec_optimal_3'),
      ];
    } else if (pressure < 1000) {
      return [
        localizations.translate('pressure_rec_low_1'),
        localizations.translate('pressure_rec_low_2'),
        localizations.translate('pressure_rec_low_3'),
      ];
    } else if (pressure > 1030) {
      return [
        localizations.translate('pressure_rec_high_1'),
        localizations.translate('pressure_rec_high_2'),
        localizations.translate('pressure_rec_high_3'),
      ];
    } else {
      return [
        localizations.translate('pressure_rec_moderate_1'),
        localizations.translate('pressure_rec_moderate_2'),
      ];
    }
  }
}