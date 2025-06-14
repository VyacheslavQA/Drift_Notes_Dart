// Путь: lib/models/weather_alert_model.dart

enum WeatherAlertType {
  pressureChange, // Изменение давления
  favorableConditions, // Благоприятные условия для рыбалки
  stormWarning, // Предупреждение о грозе/непогоде
  dailyForecast, // Утренний прогноз дня
  biteActivity, // Высокая активность клева
  windChange, // Изменение ветра
  temperatureChange, // Резкое изменение температуры
}

enum WeatherAlertPriority {
  low, // Обычная информация
  medium, // Важная информация
  high, // Критически важно
}

class WeatherAlertModel {
  final String id;
  final WeatherAlertType type;
  final String title;
  final String message;
  final WeatherAlertPriority priority;
  final DateTime createdAt;
  final Map<String, dynamic> data; // Дополнительные данные
  final bool isRead;

  WeatherAlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdAt,
    this.data = const {},
    this.isRead = false,
  });

  WeatherAlertModel copyWith({
    String? id,
    WeatherAlertType? type,
    String? title,
    String? message,
    WeatherAlertPriority? priority,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return WeatherAlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'message': message,
      'priority': priority.toString(),
      'createdAt': createdAt.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) {
    return WeatherAlertModel(
      id: json['id'] ?? '',
      type: WeatherAlertType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => WeatherAlertType.dailyForecast,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: WeatherAlertPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => WeatherAlertPriority.medium,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['isRead'] ?? false,
    );
  }

  // Получение иконки для типа уведомления
  String get iconPath {
    switch (type) {
      case WeatherAlertType.pressureChange:
        return 'assets/icons/pressure.png';
      case WeatherAlertType.favorableConditions:
        return 'assets/icons/fishing_good.png';
      case WeatherAlertType.stormWarning:
        return 'assets/icons/storm.png';
      case WeatherAlertType.dailyForecast:
        return 'assets/icons/weather.png';
      case WeatherAlertType.biteActivity:
        return 'assets/icons/fish_active.png';
      case WeatherAlertType.windChange:
        return 'assets/icons/wind.png';
      case WeatherAlertType.temperatureChange:
        return 'assets/icons/temperature.png';
    }
  }

  // Получение цвета для приоритета
  int get priorityColor {
    switch (priority) {
      case WeatherAlertPriority.low:
        return 0xFF4CAF50; // Зеленый
      case WeatherAlertPriority.medium:
        return 0xFFFF9800; // Оранжевый
      case WeatherAlertPriority.high:
        return 0xFFF44336; // Красный
    }
  }
}

// Настройки погодных уведомлений
class WeatherNotificationSettings {
  final bool enabled;
  final bool pressureChangeEnabled;
  final bool favorableConditionsEnabled;
  final bool stormWarningEnabled;
  final bool dailyForecastEnabled;
  final bool biteActivityEnabled;
  final bool windChangeEnabled;
  final bool temperatureChangeEnabled;

  // Настройки времени
  final int dailyForecastHour; // Час для утреннего прогноза (0-23)
  final int
  dailyForecastMinute; // Минуты для утреннего прогноза (0-59) - НОВОЕ ПОЛЕ
  final double pressureThreshold; // Порог изменения давления (мм рт.ст.)
  final double temperatureThreshold; // Порог изменения температуры (°C)
  final double windSpeedThreshold; // Порог скорости ветра (м/с)

  // Настройки по типам рыбалки
  final List<String> enabledFishingTypes;

  const WeatherNotificationSettings({
    this.enabled = true,
    this.pressureChangeEnabled = true,
    this.favorableConditionsEnabled = true,
    this.stormWarningEnabled = true,
    this.dailyForecastEnabled = true,
    this.biteActivityEnabled = true,
    this.windChangeEnabled = false,
    this.temperatureChangeEnabled = false,
    this.dailyForecastHour = 7,
    this.dailyForecastMinute = 0, // По умолчанию 0 минут (07:00)
    this.pressureThreshold = 5.0,
    this.temperatureThreshold = 10.0,
    this.windSpeedThreshold = 15.0,
    this.enabledFishingTypes = const [],
  });

  WeatherNotificationSettings copyWith({
    bool? enabled,
    bool? pressureChangeEnabled,
    bool? favorableConditionsEnabled,
    bool? stormWarningEnabled,
    bool? dailyForecastEnabled,
    bool? biteActivityEnabled,
    bool? windChangeEnabled,
    bool? temperatureChangeEnabled,
    int? dailyForecastHour,
    int? dailyForecastMinute, // НОВЫЙ ПАРАМЕТР
    double? pressureThreshold,
    double? temperatureThreshold,
    double? windSpeedThreshold,
    List<String>? enabledFishingTypes,
  }) {
    return WeatherNotificationSettings(
      enabled: enabled ?? this.enabled,
      pressureChangeEnabled:
          pressureChangeEnabled ?? this.pressureChangeEnabled,
      favorableConditionsEnabled:
          favorableConditionsEnabled ?? this.favorableConditionsEnabled,
      stormWarningEnabled: stormWarningEnabled ?? this.stormWarningEnabled,
      dailyForecastEnabled: dailyForecastEnabled ?? this.dailyForecastEnabled,
      biteActivityEnabled: biteActivityEnabled ?? this.biteActivityEnabled,
      windChangeEnabled: windChangeEnabled ?? this.windChangeEnabled,
      temperatureChangeEnabled:
          temperatureChangeEnabled ?? this.temperatureChangeEnabled,
      dailyForecastHour: dailyForecastHour ?? this.dailyForecastHour,
      dailyForecastMinute:
          dailyForecastMinute ?? this.dailyForecastMinute, // НОВЫЙ ПАРАМЕТР
      pressureThreshold: pressureThreshold ?? this.pressureThreshold,
      temperatureThreshold: temperatureThreshold ?? this.temperatureThreshold,
      windSpeedThreshold: windSpeedThreshold ?? this.windSpeedThreshold,
      enabledFishingTypes: enabledFishingTypes ?? this.enabledFishingTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'pressureChangeEnabled': pressureChangeEnabled,
      'favorableConditionsEnabled': favorableConditionsEnabled,
      'stormWarningEnabled': stormWarningEnabled,
      'dailyForecastEnabled': dailyForecastEnabled,
      'biteActivityEnabled': biteActivityEnabled,
      'windChangeEnabled': windChangeEnabled,
      'temperatureChangeEnabled': temperatureChangeEnabled,
      'dailyForecastHour': dailyForecastHour,
      'dailyForecastMinute': dailyForecastMinute, // НОВОЕ ПОЛЕ В JSON
      'pressureThreshold': pressureThreshold,
      'temperatureThreshold': temperatureThreshold,
      'windSpeedThreshold': windSpeedThreshold,
      'enabledFishingTypes': enabledFishingTypes,
    };
  }

  factory WeatherNotificationSettings.fromJson(Map<String, dynamic> json) {
    return WeatherNotificationSettings(
      enabled: json['enabled'] ?? true,
      pressureChangeEnabled: json['pressureChangeEnabled'] ?? true,
      favorableConditionsEnabled: json['favorableConditionsEnabled'] ?? true,
      stormWarningEnabled: json['stormWarningEnabled'] ?? true,
      dailyForecastEnabled: json['dailyForecastEnabled'] ?? true,
      biteActivityEnabled: json['biteActivityEnabled'] ?? true,
      windChangeEnabled: json['windChangeEnabled'] ?? false,
      temperatureChangeEnabled: json['temperatureChangeEnabled'] ?? false,
      dailyForecastHour: json['dailyForecastHour'] ?? 7,
      dailyForecastMinute:
          json['dailyForecastMinute'] ??
          0, // НОВОЕ ПОЛЕ С ОБРАТНОЙ СОВМЕСТИМОСТЬЮ
      pressureThreshold: (json['pressureThreshold'] ?? 5.0).toDouble(),
      temperatureThreshold: (json['temperatureThreshold'] ?? 10.0).toDouble(),
      windSpeedThreshold: (json['windSpeedThreshold'] ?? 15.0).toDouble(),
      enabledFishingTypes: List<String>.from(json['enabledFishingTypes'] ?? []),
    );
  }

  // Вспомогательный метод для форматирования времени
  String get formattedTime {
    return '${dailyForecastHour.toString().padLeft(2, '0')}:${dailyForecastMinute.toString().padLeft(2, '0')}';
  }
}
