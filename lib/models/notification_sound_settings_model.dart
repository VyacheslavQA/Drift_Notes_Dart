// Путь: lib/models/notification_sound_settings_model.dart



/// Типы системных звуков для уведомлений
enum NotificationSoundType {
  defaultSound, // Звук по умолчанию
  notification, // Звук уведомления
  alarm, // Звук будильника
  ringtone, // Мелодия звонка
  silent, // Беззвучный режим
}

/// Модель настроек звуков уведомлений
class NotificationSoundSettings {
  /// Включены ли звуковые уведомления
  final bool soundEnabled;

  /// Тип звука для уведомлений
  final NotificationSoundType soundType;

  /// Громкость звука (0.0 - 1.0)
  final double volume;

  /// Включены ли тихие часы
  final bool quietHoursEnabled;

  /// Начало тихих часов (час в 24-часовом формате)
  final int quietHoursStart;

  /// Конец тихих часов (час в 24-часовом формате)
  final int quietHoursEnd;

  /// Показывать ли бейдж на иконке приложения
  final bool badgeEnabled;

  /// Вибрация при уведомлениях
  final bool vibrationEnabled;

  const NotificationSoundSettings({
    this.soundEnabled = true,
    this.soundType = NotificationSoundType.defaultSound,
    this.volume = 0.8,
    this.quietHoursEnabled = true,
    this.quietHoursStart = 22, // 22:00
    this.quietHoursEnd = 7, // 07:00
    this.badgeEnabled = true,
    this.vibrationEnabled = true,
  });

  /// Копирование с изменениями
  NotificationSoundSettings copyWith({
    bool? soundEnabled,
    NotificationSoundType? soundType,
    double? volume,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? badgeEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSoundSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundType: soundType ?? this.soundType,
      volume: volume ?? this.volume,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  /// Проверка, находимся ли мы в тихих часах
  bool isQuietHours([DateTime? now]) {
    if (!quietHoursEnabled) return false;

    now ??= DateTime.now();
    final currentHour = now.hour;

    // Если начало больше конца, значит тихие часы переходят на следующий день
    if (quietHoursStart > quietHoursEnd) {
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    } else {
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    }
  }

  /// Должен ли проигрываться звук (учитывая тихие часы)
  bool shouldPlaySound([DateTime? now]) {
    if (!soundEnabled) return false;
    if (soundType == NotificationSoundType.silent) return false;
    return !isQuietHours(now);
  }

  /// Получение названия звука для отображения
  String getSoundDisplayName() {
    switch (soundType) {
      case NotificationSoundType.defaultSound:
        return 'По умолчанию';
      case NotificationSoundType.notification:
        return 'Уведомление';
      case NotificationSoundType.alarm:
        return 'Будильник';
      case NotificationSoundType.ringtone:
        return 'Мелодия';
      case NotificationSoundType.silent:
        return 'Без звука';
    }
  }

  /// Получение системного идентификатора звука
  String? getSystemSoundResource() {
    switch (soundType) {
      case NotificationSoundType.defaultSound:
        return null; // Использует звук по умолчанию
      case NotificationSoundType.notification:
        return 'notification';
      case NotificationSoundType.alarm:
        return 'alarm';
      case NotificationSoundType.ringtone:
        return 'ringtone';
      case NotificationSoundType.silent:
        return 'silent';
    }
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'soundType': soundType.toString(),
      'volume': volume,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'badgeEnabled': badgeEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  /// Создание из JSON
  factory NotificationSoundSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSoundSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      soundType: NotificationSoundType.values.firstWhere(
        (e) => e.toString() == json['soundType'],
        orElse: () => NotificationSoundType.defaultSound,
      ),
      volume: (json['volume'] ?? 0.8).toDouble(),
      quietHoursEnabled: json['quietHoursEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      badgeEnabled: json['badgeEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  /// Получение форматированного времени тихих часов
  String getQuietHoursDisplayText() {
    final startTime = '${quietHoursStart.toString().padLeft(2, '0')}:00';
    final endTime = '${quietHoursEnd.toString().padLeft(2, '0')}:00';
    return '$startTime - $endTime';
  }

  @override
  String toString() {
    return 'NotificationSoundSettings('
        'soundEnabled: $soundEnabled, '
        'soundType: $soundType, '
        'volume: $volume, '
        'quietHoursEnabled: $quietHoursEnabled, '
        'quietHours: ${getQuietHoursDisplayText()}, '
        'badgeEnabled: $badgeEnabled, '
        'vibrationEnabled: $vibrationEnabled'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSoundSettings &&
          runtimeType == other.runtimeType &&
          soundEnabled == other.soundEnabled &&
          soundType == other.soundType &&
          volume == other.volume &&
          quietHoursEnabled == other.quietHoursEnabled &&
          quietHoursStart == other.quietHoursStart &&
          quietHoursEnd == other.quietHoursEnd &&
          badgeEnabled == other.badgeEnabled &&
          vibrationEnabled == other.vibrationEnabled;

  @override
  int get hashCode =>
      soundEnabled.hashCode ^
      soundType.hashCode ^
      volume.hashCode ^
      quietHoursEnabled.hashCode ^
      quietHoursStart.hashCode ^
      quietHoursEnd.hashCode ^
      badgeEnabled.hashCode ^
      vibrationEnabled.hashCode;
}
