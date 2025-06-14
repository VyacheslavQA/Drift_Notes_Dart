// Путь: lib/models/notification_model.dart

enum NotificationType {
  general, // Общие уведомления
  fishingReminder, // Напоминания о рыбалке
  tournamentReminder, // НОВЫЙ: Напоминания о турнирах
  biteForecast, // Прогнозы клева
  weatherUpdate, // Обновления погоды
  newFeatures, // Новые функции
  systemUpdate, // Системные обновления
  policyUpdate, // Обновления политики конфиденциальности и соглашений
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data; // Дополнительные данные

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.general,
      ),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  // Получение иконки по типу уведомления
  String get iconPath {
    switch (type) {
      case NotificationType.general:
        return 'assets/icons/notification.png';
      case NotificationType.fishingReminder:
        return 'assets/icons/fishing.png';
      case NotificationType.tournamentReminder: // НОВЫЙ ТИП
        return 'assets/icons/tournament.png';
      case NotificationType.biteForecast:
        return 'assets/icons/fish_active.png';
      case NotificationType.weatherUpdate:
        return 'assets/icons/weather.png';
      case NotificationType.newFeatures:
        return 'assets/icons/star.png';
      case NotificationType.systemUpdate:
        return 'assets/icons/system.png';
      case NotificationType.policyUpdate:
        return 'assets/icons/security.png';
    }
  }

  // Получение цвета по типу уведомления
  int get typeColor {
    switch (type) {
      case NotificationType.general:
        return 0xFF4CAF50; // Зеленый
      case NotificationType.fishingReminder:
        return 0xFF2196F3; // Синий
      case NotificationType.tournamentReminder: // НОВЫЙ ТИП
        return 0xFFFF5722; // Оранжево-красный
      case NotificationType.biteForecast:
        return 0xFFFF9800; // Оранжевый
      case NotificationType.weatherUpdate:
        return 0xFF9C27B0; // Фиолетовый
      case NotificationType.newFeatures:
        return 0xFFFFC107; // Желтый
      case NotificationType.systemUpdate:
        return 0xFF607D8B; // Серый
      case NotificationType.policyUpdate:
        return 0xFFE91E63; // Розовый/красный
    }
  }

  // НОВЫЙ: Получение emoji-иконки для типа уведомления
  String get emoji {
    switch (type) {
      case NotificationType.general:
        return '📢';
      case NotificationType.fishingReminder:
        return '🎣';
      case NotificationType.tournamentReminder:
        return '🏆';
      case NotificationType.biteForecast:
        return '🐟';
      case NotificationType.weatherUpdate:
        return '🌤️';
      case NotificationType.newFeatures:
        return '⭐';
      case NotificationType.systemUpdate:
        return '🔧';
      case NotificationType.policyUpdate:
        return '🔒';
    }
  }

  // НОВЫЙ: Получение локализованного названия типа уведомления
  String get typeLocalizationKey {
    switch (type) {
      case NotificationType.general:
        return 'notification_type_general';
      case NotificationType.fishingReminder:
        return 'notification_type_fishing_reminder';
      case NotificationType.tournamentReminder:
        return 'notification_type_tournament_reminder';
      case NotificationType.biteForecast:
        return 'notification_type_bite_forecast';
      case NotificationType.weatherUpdate:
        return 'notification_type_weather_update';
      case NotificationType.newFeatures:
        return 'notification_type_new_features';
      case NotificationType.systemUpdate:
        return 'notification_type_system_update';
      case NotificationType.policyUpdate:
        return 'notification_type_policy_update';
    }
  }

  // НОВЫЙ: Получение приоритета уведомления (для сортировки)
  int get priority {
    switch (type) {
      case NotificationType.tournamentReminder:
        return 5; // Высокий приоритет
      case NotificationType.fishingReminder:
        return 4; // Высокий приоритет
      case NotificationType.biteForecast:
        return 3; // Средний приоритет
      case NotificationType.weatherUpdate:
        return 3; // Средний приоритет
      case NotificationType.systemUpdate:
        return 2; // Низкий приоритет
      case NotificationType.policyUpdate:
        return 2; // Низкий приоритет
      case NotificationType.newFeatures:
        return 1; // Очень низкий приоритет
      case NotificationType.general:
        return 1; // Очень низкий приоритет
    }
  }

  // НОВЫЙ: Проверка, является ли уведомление напоминанием
  bool get isReminder {
    return type == NotificationType.fishingReminder ||
        type == NotificationType.tournamentReminder;
  }

  // НОВЫЙ: Проверка, требует ли уведомление действий от пользователя
  bool get requiresAction {
    return type == NotificationType.policyUpdate ||
        type == NotificationType.systemUpdate ||
        isReminder;
  }

  // НОВЫЙ: Получение времени, через которое уведомление автоматически пропадет (в часах)
  int? get autoExpireHours {
    switch (type) {
      case NotificationType.fishingReminder:
      case NotificationType.tournamentReminder:
        return 24; // Напоминания исчезают через 24 часа
      case NotificationType.biteForecast:
        return 12; // Прогнозы исчезают через 12 часов
      case NotificationType.weatherUpdate:
        return 6; // Погода исчезает через 6 часов
      case NotificationType.general:
        return 48; // Общие уведомления через 48 часов
      case NotificationType.newFeatures:
      case NotificationType.systemUpdate:
      case NotificationType.policyUpdate:
        return null; // Не исчезают автоматически
    }
  }

  // НОВЫЙ: Проверка, истекло ли уведомление
  bool get isExpired {
    final expireHours = autoExpireHours;
    if (expireHours == null) return false;

    final expireTime = timestamp.add(Duration(hours: expireHours));
    return DateTime.now().isAfter(expireTime);
  }
}
