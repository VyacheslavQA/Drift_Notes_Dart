// Путь: lib/models/notification_model.dart

enum NotificationType {
  general,           // Общие уведомления
  fishingReminder,   // Напоминания о рыбалке
  biteForecast,      // Прогнозы клева
  weatherUpdate,     // Обновления погоды
  newFeatures,       // Новые функции
  systemUpdate,      // Системные обновления
  policyUpdate,      // Обновления политики конфиденциальности и соглашений
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
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
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
}