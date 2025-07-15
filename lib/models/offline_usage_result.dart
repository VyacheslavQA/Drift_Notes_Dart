// Путь: lib/models/offline_usage_result.dart

import 'package:flutter/material.dart';
import '../constants/subscription_constants.dart';

/// ✅ УПРОЩЕННЫЙ enum типов предупреждений (3 состояния вместо 4)
enum OfflineLimitWarningType {
  normal,    // Можно создавать (< 80% лимита)
  warning,   // Близко к лимиту (80-99% лимита)
  blocked,   // Лимит превышен (>= 100% лимита)
}

/// ✅ УПРОЩЕННЫЙ результат проверки офлайн использования
/// Убрана grace period логика и сложные вычисления
class OfflineUsageResult {
  final bool canCreate;
  final OfflineLimitWarningType warningType;
  final String message;
  final int currentUsage;
  final int limit;
  final int remaining;
  final ContentType contentType;

  const OfflineUsageResult({
    required this.canCreate,
    required this.warningType,
    required this.message,
    required this.currentUsage,
    required this.limit,
    required this.remaining,
    required this.contentType,
  });

  /// ✅ УПРОЩЕННАЯ фабрика для создания результата
  factory OfflineUsageResult.create({
    required int currentUsage,
    required int limit,
    required ContentType contentType,
    required String message,
  }) {
    final canCreate = SubscriptionConstants.canCreate(currentUsage, limit);
    final remaining = limit - currentUsage;
    final warningType = _calculateWarningType(currentUsage, limit);

    return OfflineUsageResult(
      canCreate: canCreate,
      warningType: warningType,
      message: message,
      currentUsage: currentUsage,
      limit: limit,
      remaining: remaining.clamp(0, limit),
      contentType: contentType,
    );
  }

  /// ✅ УПРОЩЕННАЯ логика определения типа предупреждения
  static OfflineLimitWarningType _calculateWarningType(int currentUsage, int limit) {
    if (limit == 0) return OfflineLimitWarningType.blocked;

    final percentage = currentUsage / limit;

    if (percentage >= 1.0) return OfflineLimitWarningType.blocked;   // >= 100%
    if (percentage >= 0.8) return OfflineLimitWarningType.warning;   // >= 80%
    return OfflineLimitWarningType.normal;                           // < 80%
  }

  /// Нужно ли показать предупреждение
  bool get shouldShowWarning => warningType != OfflineLimitWarningType.normal;

  /// Нужно ли показать диалог премиум
  bool get shouldShowPremiumDialog => warningType == OfflineLimitWarningType.blocked;

  /// ✅ УПРОЩЕННЫЙ цвет индикатора для UI
  Color get indicatorColor {
    switch (warningType) {
      case OfflineLimitWarningType.normal:
        return Colors.green;
      case OfflineLimitWarningType.warning:
        return Colors.orange;
      case OfflineLimitWarningType.blocked:
        return Colors.red;
    }
  }

  /// ✅ УПРОЩЕННАЯ иконка для UI
  IconData get indicatorIcon {
    switch (warningType) {
      case OfflineLimitWarningType.normal:
        return Icons.check_circle;
      case OfflineLimitWarningType.warning:
        return Icons.warning;
      case OfflineLimitWarningType.blocked:
        return Icons.block;
    }
  }

  /// ✅ УПРОЩЕННЫЙ процент использования (убрана grace period логика)
  double get usagePercentage {
    if (limit == 0) return 1.0; // Если лимит 0 - 100% использовано
    return (currentUsage / limit).clamp(0.0, 1.0);
  }

  /// Превышен ли лимит
  bool get isOverLimit => currentUsage >= limit;

  /// Количество элементов сверх лимита
  int get overageCount => isOverLimit ? currentUsage - limit : 0;

  /// ✅ УПРОЩЕННОЕ описание состояния для UI
  String get statusDescription {
    switch (warningType) {
      case OfflineLimitWarningType.normal:
        return 'Доступно создание $remaining ${SubscriptionConstants.getContentTypeName(contentType)}';
      case OfflineLimitWarningType.warning:
        return 'Осталось $remaining ${SubscriptionConstants.getContentTypeName(contentType)} из $limit';
      case OfflineLimitWarningType.blocked:
        return 'Лимит ${SubscriptionConstants.getContentTypeName(contentType)} исчерпан ($currentUsage/$limit)';
    }
  }

  /// ✅ ПРОСТОЙ цвет на основе процента (использует метод из констант)
  Color get progressColor => SubscriptionConstants.getLimitIndicatorColor(currentUsage, limit);

  /// Копирование с изменениями
  OfflineUsageResult copyWith({
    bool? canCreate,
    OfflineLimitWarningType? warningType,
    String? message,
    int? currentUsage,
    int? limit,
    int? remaining,
    ContentType? contentType,
  }) {
    return OfflineUsageResult(
      canCreate: canCreate ?? this.canCreate,
      warningType: warningType ?? this.warningType,
      message: message ?? this.message,
      currentUsage: currentUsage ?? this.currentUsage,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
      contentType: contentType ?? this.contentType,
    );
  }

  /// ✅ УПРОЩЕННОЕ преобразование в Map для логирования
  Map<String, dynamic> toMap() {
    return {
      'canCreate': canCreate,
      'warningType': warningType.name,
      'message': message,
      'currentUsage': currentUsage,
      'limit': limit,
      'remaining': remaining,
      'contentType': contentType.name,
      'isOverLimit': isOverLimit,
      'overageCount': overageCount,
      'usagePercentage': usagePercentage,
      'statusDescription': statusDescription,
    };
  }

  /// ✅ Удобный метод для создания результата "заблокировано"
  static OfflineUsageResult blocked({
    required int currentUsage,
    required int limit,
    required ContentType contentType,
    String? customMessage,
  }) {
    return OfflineUsageResult.create(
      currentUsage: currentUsage,
      limit: limit,
      contentType: contentType,
      message: customMessage ??
          'Лимит ${SubscriptionConstants.getContentTypeName(contentType)} превышен. '
              'Приобретите премиум для безлимитного использования.',
    );
  }

  /// ✅ Удобный метод для создания результата "доступно"
  static OfflineUsageResult available({
    required int currentUsage,
    required int limit,
    required ContentType contentType,
    String? customMessage,
  }) {
    return OfflineUsageResult.create(
      currentUsage: currentUsage,
      limit: limit,
      contentType: contentType,
      message: customMessage ??
          'Доступно создание ${limit - currentUsage} ${SubscriptionConstants.getContentTypeName(contentType)}',
    );
  }

  /// ✅ Удобный метод для создания результата "предупреждение"
  static OfflineUsageResult warning({
    required int currentUsage,
    required int limit,
    required ContentType contentType,
    String? customMessage,
  }) {
    return OfflineUsageResult.create(
      currentUsage: currentUsage,
      limit: limit,
      contentType: contentType,
      message: customMessage ??
          'Приближается лимит ${SubscriptionConstants.getContentTypeName(contentType)}. '
              'Осталось ${limit - currentUsage} из $limit.',
    );
  }

  @override
  String toString() {
    return 'OfflineUsageResult(canCreate: $canCreate, warningType: $warningType, '
        'currentUsage: $currentUsage, limit: $limit, remaining: $remaining, '
        'contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OfflineUsageResult &&
        other.canCreate == canCreate &&
        other.warningType == warningType &&
        other.message == message &&
        other.currentUsage == currentUsage &&
        other.limit == limit &&
        other.remaining == remaining &&
        other.contentType == contentType;
  }

  @override
  int get hashCode {
    return canCreate.hashCode ^
    warningType.hashCode ^
    message.hashCode ^
    currentUsage.hashCode ^
    limit.hashCode ^
    remaining.hashCode ^
    contentType.hashCode;
  }
}