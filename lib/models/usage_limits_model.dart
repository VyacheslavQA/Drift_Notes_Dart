// Путь: lib/models/usage_limits_model.dart

import '../constants/subscription_constants.dart';

/// ✅ ИСПРАВЛЕННАЯ модель для отслеживания использования лимитов пользователем
/// expenses → budgetNotes везде в коде
class UsageLimitsModel {
  final String userId;
  final int notesCount;
  final int markerMapsCount;
  final int budgetNotesCount;  // ✅ ИСПРАВЛЕНО! Было expensesCount
  final DateTime lastResetDate;
  final DateTime updatedAt;

  const UsageLimitsModel({
    required this.userId,
    required this.notesCount,
    required this.markerMapsCount,
    required this.budgetNotesCount,  // ✅ ИСПРАВЛЕНО! Было expensesCount
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
      budgetNotesCount: 0,  // ✅ ИСПРАВЛЕНО! Было expensesCount
      lastResetDate: now,
      updatedAt: now,
    );
  }

  /// ✅ ИСПРАВЛЕНО: Создание из Map с правильными константами
  factory UsageLimitsModel.fromMap(Map<String, dynamic> map, String userId) {
    return UsageLimitsModel(
      userId: userId,
      notesCount: (map[SubscriptionConstants.notesCountField] as num?)?.toInt() ?? 0,
      markerMapsCount: (map[SubscriptionConstants.markerMapsCountField] as num?)?.toInt() ?? 0,
      budgetNotesCount: (map[SubscriptionConstants.budgetNotesCountField] as num?)?.toInt() ?? 0,  // ✅ ИСПРАВЛЕНО!
      lastResetDate: _parseDateTime(map[SubscriptionConstants.lastResetDateField]) ?? DateTime.now(),
      updatedAt: _parseDateTime(map[SubscriptionConstants.updatedAtField]) ?? DateTime.now(),
    );
  }

  /// ✅ ИСПРАВЛЕНО: Преобразование в Map с правильными константами
  Map<String, dynamic> toMap() {
    return {
      SubscriptionConstants.notesCountField: notesCount,
      SubscriptionConstants.markerMapsCountField: markerMapsCount,
      SubscriptionConstants.budgetNotesCountField: budgetNotesCount,  // ✅ ИСПРАВЛЕНО!
      SubscriptionConstants.lastResetDateField: lastResetDate.toIso8601String(),
      SubscriptionConstants.updatedAtField: updatedAt.toIso8601String(),
    };
  }

  /// ✅ ИСПРАВЛЕНО: Копирование с новым полем budgetNotesCount
  UsageLimitsModel copyWith({
    String? userId,
    int? notesCount,
    int? markerMapsCount,
    int? budgetNotesCount,  // ✅ ИСПРАВЛЕНО! Было expensesCount
    DateTime? lastResetDate,
    DateTime? updatedAt,
  }) {
    return UsageLimitsModel(
      userId: userId ?? this.userId,
      notesCount: notesCount ?? this.notesCount,
      markerMapsCount: markerMapsCount ?? this.markerMapsCount,
      budgetNotesCount: budgetNotesCount ?? this.budgetNotesCount,  // ✅ ИСПРАВЛЕНО!
      lastResetDate: lastResetDate ?? this.lastResetDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 🚀 ИСПРАВЛЕНО: Увеличение счетчика с поддержкой markerMapSharing
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
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return copyWith(
          budgetNotesCount: budgetNotesCount + 1,  // ✅ ИСПРАВЛЕНО!
          updatedAt: now,
        );
      case ContentType.depthChart:
      // График глубин не имеет счетчика, он полностью заблокирован
        return copyWith(updatedAt: now);
      case ContentType.markerMapSharing: // 🚀 НОВОЕ
      // Обмен картами использует тот же счетчик что и маркерные карты
        return copyWith(
          markerMapsCount: markerMapsCount + 1,
          updatedAt: now,
        );
    }
  }

  /// 🚀 ИСПРАВЛЕНО: Уменьшение счетчика с поддержкой markerMapSharing
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
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return copyWith(
          budgetNotesCount: (budgetNotesCount - 1).clamp(0, double.infinity).toInt(),  // ✅ ИСПРАВЛЕНО!
          updatedAt: now,
        );
      case ContentType.depthChart:
      // График глубин не имеет счетчика
        return copyWith(updatedAt: now);
      case ContentType.markerMapSharing: // 🚀 НОВОЕ
      // Обмен картами использует тот же счетчик что и маркерные карты
        return copyWith(
          markerMapsCount: (markerMapsCount - 1).clamp(0, double.infinity).toInt(),
          updatedAt: now,
        );
    }
  }

  /// 🚀 ИСПРАВЛЕНО: Получение счетчика с поддержкой markerMapSharing
  int getCountForType(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return notesCount;
      case ContentType.markerMaps:
        return markerMapsCount;
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return budgetNotesCount;  // ✅ ИСПРАВЛЕНО!
      case ContentType.depthChart:
        return 0; // График глубин не имеет счетчика
      case ContentType.markerMapSharing: // 🚀 НОВОЕ
        return markerMapsCount; // Использует тот же счетчик что и маркерные карты
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
    // Для графика глубин и обмена картами всегда false (полностью заблокированы)
    if (contentType == ContentType.depthChart ||
        contentType == ContentType.markerMapSharing) { // 🚀 НОВОЕ
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

  /// ✅ ИСПРАВЛЕНО: Сброс всех счетчиков с правильным полем
  UsageLimitsModel resetAllCounters() {
    final now = DateTime.now();
    return copyWith(
      notesCount: 0,
      markerMapsCount: 0,
      budgetNotesCount: 0,  // ✅ ИСПРАВЛЕНО! Было expensesCount
      lastResetDate: now,
      updatedAt: now,
    );
  }

  /// ✅ ИСПРАВЛЕНО: Общее количество с правильным полем
  int get totalContentCount => notesCount + markerMapsCount + budgetNotesCount;  // ✅ ИСПРАВЛЕНО!

  /// Проверка есть ли хотя бы один созданный элемент
  bool get hasAnyContent => totalContentCount > 0;

  /// ✅ ИСПРАВЛЕНО: Статистика с правильными названиями и константами
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
      'budgetNotes': {  // ✅ ИСПРАВЛЕНО! Было 'expenses'
        'current': budgetNotesCount,  // ✅ ИСПРАВЛЕНО!
        'limit': SubscriptionConstants.freeBudgetNotesLimit,  // ✅ ИСПРАВЛЕНО!
        'remaining': getRemainingCount(ContentType.budgetNotes),  // ✅ ИСПРАВЛЕНО!
        'percentage': getUsagePercentage(ContentType.budgetNotes),  // ✅ ИСПРАВЛЕНО!
      },
      'total': totalContentCount,
    };
  }

  /// ✅ НОВЫЙ: Получение статистики для конкретного типа контента
  Map<String, dynamic> getStatsForType(ContentType contentType) {
    return {
      'current': getCountForType(contentType),
      'limit': SubscriptionConstants.getContentLimit(contentType),
      'remaining': getRemainingCount(contentType),
      'percentage': getUsagePercentage(contentType),
      'canCreate': canCreateNew(contentType),
      'shouldWarn': shouldShowWarning(contentType),
      'typeName': SubscriptionConstants.getContentTypeName(contentType),
    };
  }

  /// ✅ НОВЫЙ: Проверка есть ли достигнутые лимиты
  bool get hasAnyLimitReached {
    return hasReachedLimit(ContentType.fishingNotes) ||
        hasReachedLimit(ContentType.markerMaps) ||
        hasReachedLimit(ContentType.budgetNotes);
  }

  /// ✅ НОВЫЙ: Получение списка достигнутых лимитов
  List<ContentType> get reachedLimits {
    final List<ContentType> reached = [];

    if (hasReachedLimit(ContentType.fishingNotes)) {
      reached.add(ContentType.fishingNotes);
    }
    if (hasReachedLimit(ContentType.markerMaps)) {
      reached.add(ContentType.markerMaps);
    }
    if (hasReachedLimit(ContentType.budgetNotes)) {
      reached.add(ContentType.budgetNotes);
    }

    return reached;
  }

  /// ✅ НОВЫЙ: Быстрая проверка может ли пользователь создавать что-либо
  bool get canCreateAnyContent {
    return canCreateNew(ContentType.fishingNotes) ||
        canCreateNew(ContentType.markerMaps) ||
        canCreateNew(ContentType.budgetNotes);
  }

  // ========================================
  // ПРИВАТНЫЕ МЕТОДЫ
  // ========================================

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      // Для Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate() as DateTime;
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
        'budgetNotes: $budgetNotesCount/${SubscriptionConstants.freeBudgetNotesLimit}, '  // ✅ ИСПРАВЛЕНО!
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
        other.budgetNotesCount == budgetNotesCount &&  // ✅ ИСПРАВЛЕНО!
        other.lastResetDate == lastResetDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      notesCount,
      markerMapsCount,
      budgetNotesCount,  // ✅ ИСПРАВЛЕНО!
      lastResetDate,
    );
  }
}