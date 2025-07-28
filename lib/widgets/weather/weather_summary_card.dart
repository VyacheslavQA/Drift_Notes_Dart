import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/weather_api_model.dart';
import '../../services/weather_settings_service.dart';
import '../../localization/app_localizations.dart';

class WeatherSummaryCard extends StatelessWidget {
  final WeatherApiResponse weather;
  final WeatherSettingsService weatherSettings;
  final int selectedDayIndex;
  final String locationName;

  const WeatherSummaryCard({
    super.key,
    required this.weather,
    required this.weatherSettings,
    required this.selectedDayIndex,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selectedDay = weather.forecast[selectedDayIndex];

    // Определяем текущие или прогнозные данные
    final bool isToday = selectedDayIndex == 0;

    // Температура
    final currentTemp = isToday
        ? weather.current.tempC.round()
        : ((selectedDay.day.maxtempC + selectedDay.day.mintempC) / 2).round();

    // Ощущаемая температура
    final feelsLike = isToday
        ? weather.current.feelslikeC.round()
        : currentTemp; // Для других дней используем среднюю

    // Описание погоды с переводом
    final conditionText = isToday
        ? weather.current.condition.text
        : selectedDay.day.condition.text;
    final condition = localizations.translate(conditionText) ?? conditionText;

    // Влажность - вычисляем среднюю из почасовых данных для других дней
    final humidity = isToday
        ? weather.current.humidity
        : _calculateAverageHumidity(selectedDay.hour);

    // Скорость ветра - вычисляем среднюю из почасовых данных
    final windSpeed = isToday
        ? weather.current.windKph
        : _calculateAverageWindSpeed(selectedDay.hour);

    // Видимость
    final visibility = isToday
        ? weather.current.visKm
        : 10.0; // Для других дней используем значение по умолчанию

    // Вероятность дождя - берем максимальную из почасовых данных
    final rainChance = _calculateMaxRainChance(selectedDay.hour);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с временем
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationName,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Описание погоды с динамическим заголовком
          Row(
            children: [
              const Text('☀️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                _getWeatherTitle(context, selectedDayIndex),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Основная температура и информация
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая часть - температура
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Большая температура
                    Text(
                      '${currentTemp}°',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        height: 0.9,
                        letterSpacing: -2,
                      ),
                    ),

                    // Описание погоды
                    Text(
                      condition,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Правая часть - дополнительная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Вероятность дождя
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('☁️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${rainChance.round()}%',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Описание вероятности дождя
                    Text(
                      rainChance > 50
                          ? localizations.translate('high_rain_chance')
                          : rainChance > 20
                          ? localizations.translate('possible_rain')
                          : localizations.translate('low_rain_chance'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Нижняя строка с метриками
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // По ощущениям
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('feels_like'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${feelsLike}°',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Видимость
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    localizations.translate('visibility'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${visibility.toInt()} ${localizations.translate('km')}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Метод для получения динамического заголовка
  String _getWeatherTitle(BuildContext context, int dayIndex) {
    final localizations = AppLocalizations.of(context);

    switch (dayIndex) {
      case 0:
        return localizations.translate('current_weather');
      case 1:
        return localizations.translate('tomorrow_forecast');
      default:
      // Для других дней показываем дату
        final selectedDay = weather.forecast[dayIndex];
        final date = DateTime.parse(selectedDay.date);
        final formattedDate = _formatDate(date, localizations);
        return '${localizations.translate('forecast_for')} $formattedDate';
    }
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date, dynamic localizations) {
    // Используем ключи месяцев в родительном падеже (для дат)
    final monthsGenitive = [
      localizations.translate('january_genitive') ?? 'января',
      localizations.translate('february_genitive') ?? 'февраля',
      localizations.translate('march_genitive') ?? 'марта',
      localizations.translate('april_genitive') ?? 'апреля',
      localizations.translate('may_genitive') ?? 'мая',
      localizations.translate('june_genitive') ?? 'июня',
      localizations.translate('july_genitive') ?? 'июля',
      localizations.translate('august_genitive') ?? 'августа',
      localizations.translate('september_genitive') ?? 'сентября',
      localizations.translate('october_genitive') ?? 'октября',
      localizations.translate('november_genitive') ?? 'ноября',
      localizations.translate('december_genitive') ?? 'декабря',
    ];

    return '${date.day} ${monthsGenitive[date.month - 1]}';
  }

  int _calculateAverageHumidity(List<Hour> hours) {
    if (hours.isEmpty) return 50; // значение по умолчанию

    final total = hours.fold<int>(0, (sum, hour) => sum + hour.humidity);
    return (total / hours.length).round();
  }

  double _calculateAverageWindSpeed(List<Hour> hours) {
    if (hours.isEmpty) return 10.0; // значение по умолчанию

    final total = hours.fold<double>(0.0, (sum, hour) => sum + hour.windKph);
    return total / hours.length;
  }

  double _calculateMaxRainChance(List<Hour> hours) {
    if (hours.isEmpty) return 0.0; // значение по умолчанию

    return hours.fold<double>(0.0, (max, hour) =>
    hour.chanceOfRain > max ? hour.chanceOfRain : max);
  }
}