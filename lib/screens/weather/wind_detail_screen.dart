// Путь: lib/screens/weather/wind_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui; // Добавляем импорт для TextDirection
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../localization/app_localizations.dart';

class WindDetailScreen extends StatefulWidget {
  final WeatherApiResponse weatherData;
  final String locationName;

  const WindDetailScreen({
    super.key,
    required this.weatherData,
    required this.locationName,
  });

  @override
  State<WindDetailScreen> createState() => _WindDetailScreenState();
}

class _WindDetailScreenState extends State<WindDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _compassController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _compassAnimation;

  List<FlSpot> _windSpeedSpots = [];
  List<String> _timeLabels = [];
  List<String> _windDirections = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateWindData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _compassController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _compassAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _compassController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
    _compassController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _compassController.dispose();
    super.dispose();
  }

  void _generateWindData() {
    _windSpeedSpots.clear();
    _timeLabels.clear();
    _windDirections.clear();

    final baseWindSpeed = widget.weatherData.current.windKph;
    final baseDirection = widget.weatherData.current.windDir;
    final now = DateTime.now();

    // Генерируем данные за последние 12 часов и следующие 12 часов
    for (int i = -12; i <= 12; i++) {
      final time = now.add(Duration(hours: i));

      // Имитируем изменения скорости ветра
      final timeVariation = math.sin(i * math.pi / 6) * 3; // Циклическое изменение
      final randomVariation = (math.Random().nextDouble() - 0.5) * 4;
      final windSpeed = math.max(0.0, baseWindSpeed + timeVariation + randomVariation);

      _windSpeedSpots.add(FlSpot(i.toDouble() + 12, windSpeed.toDouble())); // Исправлено: добавлен .toDouble()

      // Имитируем изменения направления ветра
      _windDirections.add(baseDirection);

      if (i % 3 == 0) {
        _timeLabels.add(DateFormat('HH:mm').format(time));
      } else {
        _timeLabels.add('');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentWind = widget.weatherData.current;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('wind_analysis'),
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
              // Текущий ветер - главная карточка
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: _buildCurrentWindCard(currentWind),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Компас и направление
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 1.5),
                    child: _buildWindCompassCard(currentWind),
                  );
                },
              ),

              const SizedBox(height: 24),

              // График скорости ветра
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 2),
                    child: _buildWindSpeedChart(),
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
                    child: _buildFishingImpactCard(currentWind),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Рекомендации по местам ловли
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 3),
                    child: _buildLocationRecommendationsCard(currentWind),
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

  Widget _buildCurrentWindCard(Current currentWind) {
    final localizations = AppLocalizations.of(context);
    final windSpeedMs = (currentWind.windKph / 3.6).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            AppConstants.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
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
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.air,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('current_wind'),
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

          // Основные показатели ветра
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Скорость
              Column(
                children: [
                  Text(
                    localizations.translate('speed'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        windSpeedMs.toString(),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 40,
                          fontWeight: FontWeight.w200,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          'м/с',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentWind.windKph.round()} км/ч',
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Разделитель
              Container(
                height: 80,
                width: 1,
                color: AppConstants.textColor.withValues(alpha: 0.2),
              ),

              // Направление
              Column(
                children: [
                  Text(
                    localizations.translate('direction'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentWind.windDir,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translateWindDirection(currentWind.windDir),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Статус ветра
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getWindStatusColor(currentWind.windKph).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getWindStatusColor(currentWind.windKph).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getWindStatus(currentWind.windKph),
              style: TextStyle(
                color: _getWindStatusColor(currentWind.windKph),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCompassCard(Current currentWind) {
    final localizations = AppLocalizations.of(context);

    return Container(
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
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('wind_direction_compass'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Компас
          AnimatedBuilder(
            animation: _compassAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  children: [
                    // Основной круг компаса
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.textColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            AppConstants.backgroundColor.withValues(alpha: 0.3),
                            AppConstants.surfaceColor,
                          ],
                        ),
                      ),
                    ),

                    // Направления света
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: CompassPainter(
                        animation: _compassAnimation.value,
                        textColor: AppConstants.textColor,
                      ),
                    ),

                    // Стрелка ветра
                    Center(
                      child: Transform.rotate(
                        angle: _getWindAngle(currentWind.windDir) * _compassAnimation.value,
                        child: Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Центральная точка
                    Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompassInfo(
                      localizations.translate('current_direction'),
                      '${currentWind.windDir} (${_getWindDegrees(currentWind.windDir)}°)',
                    ),
                    _buildCompassInfo(
                      localizations.translate('best_fishing_side'),
                      _getBestFishingSide(currentWind.windDir),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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

  Widget _buildWindSpeedChart() {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 280,
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
                localizations.translate('wind_speed_trend'),
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
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
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
                      interval: 3,
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
                    spots: _windSpeedSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
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
                          Colors.blue.withValues(alpha: 0.3),
                          Colors.blue.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: _windSpeedSpots.map((spot) => spot.y).reduce(math.max) + 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingImpactCard(Current currentWind) {
    final localizations = AppLocalizations.of(context);
    final impact = _getWindFishingImpact(currentWind.windKph);

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
                  localizations.translate('fishing_conditions'),
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

          const SizedBox(height: 16),

          // Дополнительная информация
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWindInfoRow(
                  localizations.translate('wave_height'),
                  _getWaveHeight(currentWind.windKph),
                  Icons.waves,
                ),
                const SizedBox(height: 8),
                _buildWindInfoRow(
                  localizations.translate('fishing_difficulty'),
                  _getFishingDifficulty(currentWind.windKph),
                  Icons.trending_up,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRecommendationsCard(Current currentWind) {
    final localizations = AppLocalizations.of(context);
    final recommendations = _getLocationRecommendations(currentWind);

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
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.place,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.translate('location_recommendations'),
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

          ...recommendations.map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rec['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rec['color'].withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      rec['icon'],
                      color: rec['color'],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec['title'],
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rec['description'],
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    height: 1.4,
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

  String _translateWindDirection(String direction) {
    final localizations = AppLocalizations.of(context);
    final Map<String, String> translations = {
      'N': localizations.translate('wind_n'),
      'NNE': localizations.translate('wind_nne'),
      'NE': localizations.translate('wind_ne'),
      'ENE': localizations.translate('wind_ene'),
      'E': localizations.translate('wind_e'),
      'ESE': localizations.translate('wind_ese'),
      'SE': localizations.translate('wind_se'),
      'SSE': localizations.translate('wind_sse'),
      'S': localizations.translate('wind_s'),
      'SSW': localizations.translate('wind_ssw'),
      'SW': localizations.translate('wind_sw'),
      'WSW': localizations.translate('wind_wsw'),
      'W': localizations.translate('wind_w'),
      'WNW': localizations.translate('wind_wnw'),
      'NW': localizations.translate('wind_nw'),
      'NNW': localizations.translate('wind_nnw'),
    };
    return translations[direction] ?? direction;
  }

  Color _getWindStatusColor(double windKph) {
    if (windKph < 10) return Colors.green;
    if (windKph < 20) return Colors.lightGreen;
    if (windKph < 30) return Colors.orange;
    return Colors.red;
  }

  String _getWindStatus(double windKph) {
    final localizations = AppLocalizations.of(context);
    if (windKph < 10) return localizations.translate('excellent_for_fishing');
    if (windKph < 20) return localizations.translate('good_for_fishing');
    if (windKph < 30) return localizations.translate('moderate_for_fishing');
    return localizations.translate('difficult_for_fishing');
  }

  double _getWindAngle(String direction) {
    final Map<String, double> angles = {
      'N': 0, 'NNE': 22.5, 'NE': 45, 'ENE': 67.5,
      'E': 90, 'ESE': 112.5, 'SE': 135, 'SSE': 157.5,
      'S': 180, 'SSW': 202.5, 'SW': 225, 'WSW': 247.5,
      'W': 270, 'WNW': 292.5, 'NW': 315, 'NNW': 337.5,
    };
    return (angles[direction] ?? 0) * math.pi / 180;
  }

  String _getWindDegrees(String direction) {
    final Map<String, int> degrees = {
      'N': 0, 'NNE': 23, 'NE': 45, 'ENE': 68,
      'E': 90, 'ESE': 113, 'SE': 135, 'SSE': 158,
      'S': 180, 'SSW': 203, 'SW': 225, 'WSW': 248,
      'W': 270, 'WNW': 293, 'NW': 315, 'NNW': 338,
    };
    return degrees[direction]?.toString() ?? '0';
  }

  String _getBestFishingSide(String windDirection) {
    final localizations = AppLocalizations.of(context);
    final Map<String, String> bestSides = {
      'N': localizations.translate('south_side'),
      'NE': localizations.translate('southwest_side'),
      'E': localizations.translate('west_side'),
      'SE': localizations.translate('northwest_side'),
      'S': localizations.translate('north_side'),
      'SW': localizations.translate('northeast_side'),
      'W': localizations.translate('east_side'),
      'NW': localizations.translate('southeast_side'),
    };
    return bestSides[windDirection] ?? localizations.translate('windward_side');
  }

  Map<String, dynamic> _getWindFishingImpact(double windKph) {
    final localizations = AppLocalizations.of(context);

    if (windKph < 10) {
      return {
        'level': localizations.translate('excellent_conditions'),
        'description': localizations.translate('wind_excellent_description'),
        'color': Colors.green,
      };
    } else if (windKph < 20) {
      return {
        'level': localizations.translate('good_conditions'),
        'description': localizations.translate('wind_good_description'),
        'color': Colors.lightGreen,
      };
    } else if (windKph < 30) {
      return {
        'level': localizations.translate('moderate_conditions'),
        'description': localizations.translate('wind_moderate_description'),
        'color': Colors.orange,
      };
    } else {
      return {
        'level': localizations.translate('difficult_conditions'),
        'description': localizations.translate('wind_difficult_description'),
        'color': Colors.red,
      };
    }
  }

  String _getWaveHeight(double windKph) {
    if (windKph < 10) return '0.1-0.3 м';
    if (windKph < 20) return '0.3-0.6 м';
    if (windKph < 30) return '0.6-1.0 м';
    return '1.0+ м';
  }

  String _getFishingDifficulty(double windKph) {
    final localizations = AppLocalizations.of(context);
    if (windKph < 10) return localizations.translate('easy');
    if (windKph < 20) return localizations.translate('moderate');
    if (windKph < 30) return localizations.translate('difficult');
    return localizations.translate('very_difficult');
  }

  List<Map<String, dynamic>> _getLocationRecommendations(Current currentWind) {
    final localizations = AppLocalizations.of(context);
    final windKph = currentWind.windKph;

    List<Map<String, dynamic>> recommendations = [];

    if (windKph < 15) {
      recommendations.add({
        'title': localizations.translate('open_water_fishing'),
        'description': localizations.translate('open_water_recommendation'),
        'icon': Icons.waves,
        'color': Colors.blue,
      });
    }

    recommendations.add({
      'title': localizations.translate('sheltered_areas'),
      'description': localizations.translate('sheltered_areas_recommendation'),
      'icon': Icons.forest,
      'color': Colors.green,
    });

    if (windKph > 20) {
      recommendations.add({
        'title': localizations.translate('avoid_exposed_areas'),
        'description': localizations.translate('avoid_exposed_recommendation'),
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }

    recommendations.add({
      'title': localizations.translate('windward_fishing'),
      'description': localizations.translate('windward_fishing_recommendation'),
      'icon': Icons.trending_up,
      'color': Colors.orange,
    });

    return recommendations;
  }
}

// Кастомный painter для компаса
class CompassPainter extends CustomPainter {
  final double animation;
  final Color textColor;

  CompassPainter({required this.animation, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = textColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    final Paint mainLinePaint = Paint()
      ..color = textColor.withValues(alpha: 0.8)
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Рисуем основные направления
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * math.pi / 180;
      final startX = center.dx + (radius - 15) * math.cos(angle - math.pi / 2);
      final startY = center.dy + (radius - 15) * math.sin(angle - math.pi / 2);
      final endX = center.dx + radius * math.cos(angle - math.pi / 2);
      final endY = center.dy + radius * math.sin(angle - math.pi / 2);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        mainLinePaint,
      );

      // Рисуем буквы направлений
      final textSpan = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: textColor,
          fontSize: 16 * animation,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr, // Исправлено: добавлен ui. префикс
      );
      textPainter.layout();

      final textX = center.dx + (radius + 15) * math.cos(angle - math.pi / 2) - textPainter.width / 2;
      final textY = center.dy + (radius + 15) * math.sin(angle - math.pi / 2) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Рисуем промежуточные деления
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 + 22.5) * math.pi / 180;
      final startX = center.dx + (radius - 8) * math.cos(angle - math.pi / 2);
      final startY = center.dy + (radius - 8) * math.sin(angle - math.pi / 2);
      final endX = center.dx + radius * math.cos(angle - math.pi / 2);
      final endY = center.dy + radius * math.sin(angle - math.pi / 2);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}