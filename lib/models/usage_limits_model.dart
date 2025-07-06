// Путь: lib/models/usage_limits_model.dart

import '../constants/subscription_constants.dart';

/// Модель для отслеживания использования лимитов пользователем
class UsageLimitsModel {
  final String userId;
  final int notesCount;
  final int markerMapsCount;
  final int expensesCount;
  final DateTime lastResetDate;
  final DateTime updatedAt;

  const UsageLimitsModel({
    required this.userId,
    required this.notesCount,
    required this.markerMapsCount,
    required this.expensesCount,
    required this.lastResetDate,
    required this.updatedAt,
  });

  /// Создание модели по умолчанию (все счетчики в 0)
  factory UsageLimitsModel.defaultLimits(String userId) {
    final now = DateTime.now();
    return UsageLimitsModel(
      userId: userId,
      notesCount: 0,
      markerMapsCount: 0,
      expensesCount: 0,
      lastResetDate: now,
      updatedAt: now,
    );
  }

  /// Создание из Map (для Firebase)
  factory UsageLimitsModel.fromMap(Map<String, dynamic> map, String userId) {
    return UsageLimitsModel(
      userId: userId,
      notesCount: (map[SubscriptionConstants.notesCountField] as num?)?.toInt() ?? 0,
      markerMapsCount: (map[SubscriptionConstants.markerMapsCountField] as num?)?.toInt() ?? 0,
      expensesCount: (map[SubscriptionConstants.expensesCountField] as num?)?.toInt() ?? 0,
      lastResetDate: _parseDateTime(map[SubscriptionConstants.lastResetDateField]) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Преобразование в Map (для Firebase)
  Map<String, dynamic> toMap() {
    return {
      SubscriptionConstants.notesCountField: notesCount,
      SubscriptionConstants.markerMapsCountField: markerMapsCount,
      SubscriptionConstants.expensesCountField: expensesCount,
      SubscriptionConstants.lastResetDateField: lastResetDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Копирование с изменениями
  UsageLimitsModel copyWith({
    String? userId,
    int? notesCount,
    int? markerMapsCount,
    int? expensesCount,
    DateTime? lastResetDate,
    DateTime? updatedAt,
  }) {
    return UsageLimitsModel(
      userId: userId ?? this.userId,
      notesCount: notesCount ?? this.notesCount,
      markerMapsCount: markerMapsCount ?? this.markerMapsCount,
      expensesCount: expensesCount ?? this.expensesCount,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Увеличение счетчика для определенного типа контента
  UsageLimitsModel incrementCounter(ContentType contentType) {
    final now = DateTime.now();

    switch (contentType) {
      case ContentType.fishingNotes:
        return copyWith(
          notesCount: notesCount + 1,
          updatedAt: now,
        );
      case ContentType.markerMaps:
        return copyWith(
          markerMapsCount: markerMapsCount + 1,
          updatedAt: now,
        );
      case ContentType.expenses:
        return copyWith(
          expensesCount: expensesCount + 1,
          updatedAt: now,
        );
      case ContentType.depthChart:
      // График глубин не имеет счетчика, он полностью заблокирован
        return copyWith(updatedAt: now);
    }
  }

  /// Уменьшение счетчика для определенного типа контента (при удалении)
  UsageLimitsModel decrementCounter(ContentType contentType) {
    final now = DateTime.now();

    switch (contentType) {
      case ContentType.fishingNotes:
        return copyWith(
          notesCount: (notesCount - 1).clamp(0, double.infinity).toInt(),
          updatedAt: now,
        );
      case ContentType.markerMaps:
        return copyWith(
          markerMapsCount: (markerMapsCount - 1).clamp(0, double.infinity).toInt(),
          updatedAt: now,
        );
      case ContentType.expenses:
        return copyWith(
          expensesCount: (expensesCount - 1).clamp(0, double.infinity).toInt(),
          updatedAt: now,
        );
      case ContentType.depthChart:
      // График глубин не имеет счетчика
        return copyWith(updatedAt: now);
    }
  }

  /// Получение текущего значения счетчика для типа контента
  int getCountForType(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return notesCount;
      case ContentType.markerMaps:
        return markerMapsCount;
      case ContentType.expenses:
        return expensesCount;
      case ContentType.depthChart:
        return 0; // График глубин не имеет счетчика
    }
  }

  /// Проверка достижения лимита для типа контента
  bool hasReachedLimit(ContentType contentType) {
    final currentCount = getCountForType(contentType);
    final limit = SubscriptionConstants.getContentLimit(contentType);

    return currentCount >= limit;
  }

  /// Проверка можно ли создать новый элемент данного типа
  bool canCreateNew(ContentType contentType) {
    // Для графика глубин всегда false (полностью заблокирован)
    if (contentType == ContentType.depthChart) {
      return false;
    }

    return !hasReachedLimit(contentType);
  }

  /// Получение оставшегося количества для типа контента
  int getRemainingCount(ContentType contentType) {
    final currentCount = getCountForType(contentType);
    final limit = SubscriptionConstants.getContentLimit(contentType);
    final remaining = limit - currentCount;

    return remaining.clamp(0, double.infinity).toInt();
  }

  /// Получение процента использования для типа контента (0.0 - 1.0)
  double getUsagePercentage(ContentType contentType) {
    final currentCount = getCountForType(contentType);
    final limit = SubscriptionConstants.getContentLimit(contentType);

    if (limit == 0) return 0.0;

    return (currentCount / limit).clamp(0.0, 1.0);
  }

  /// Проверка нужно ли показывать предупреждение (достигнуто 80% лимита)
  bool shouldShowWarning(ContentType contentType) {
    final percentage = getUsagePercentage(contentType);
    return percentage >= 0.8 && percentage < 1.0;
  }

  /// Сброс всех счетчиков (для тестирования или админских функций)
  UsageLimitsModel resetAllCounters() {
    final now = DateTime.now();
    return copyWith(
      notesCount: 0,
      markerMapsCount: 0,
      expensesCount: 0,
      lastResetDate: now,
      updatedAt: now,
    );
  }

  /// Общее количество созданного контента
  int get totalContentCount => notesCount + markerMapsCount + expensesCount;

  /// Проверка есть ли хотя бы один созданный элемент
  bool get hasAnyContent => totalContentCount > 0;

  /// Получение краткой статистики
  Map<String, dynamic> getUsageStats() {
    return {
      'notes': {
        'current': notesCount,
        'limit': SubscriptionConstants.freeNotesLimit,
        'remaining': getRemainingCount(ContentType.fishingNotes),
        'percentage': getUsagePercentage(ContentType.fishingNotes),
      },
      'maps': {
        'current': markerMapsCount,
        'limit': SubscriptionConstants.freeMarkerMapsLimit,
        'remaining': getRemainingCount(ContentType.markerMaps),
        'percentage': getUsagePercentage(ContentType.markerMaps),
      },
      'expenses': {
        'current': expensesCount,
        'limit': SubscriptionConstants.freeExpensesLimit,
        'remaining': getRemainingCount(ContentType.expenses),
        'percentage': getUsagePercentage(ContentType.expenses),
      },
      'total': totalContentCount,
    };
  }

  // Приватные методы

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      // Для Firestore Timestamp
      if (value.toString().contains('Timestamp')) {
        return value.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'UsageLimitsModel('
        'userId: $userId, '
        'notes: $notesCount/${SubscriptionConstants.freeNotesLimit}, '
        'maps: $markerMapsCount/${SubscriptionConstants.freeMarkerMapsLimit}, '
        'expenses: $expensesCount/${SubscriptionConstants.freeExpensesLimit}, '
        'total: $totalContentCount'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UsageLimitsModel &&
        other.userId == userId &&
        other.notesCount == notesCount &&
        other.markerMapsCount == markerMapsCount &&
        other.expensesCount == expensesCount &&
        other.lastResetDate == lastResetDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      notesCount,
      markerMapsCount,
      expensesCount,
      lastResetDate,
    );
  }
}