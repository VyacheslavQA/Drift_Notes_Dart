// Путь: lib/models/offline_usage_result.dart

import 'package:flutter/material.dart';
import '../constants/subscription_constants.dart';

/// Результат проверки офлайн использования
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

  /// Нужно ли показать предупреждение
  bool get shouldShowWarning => warningType != OfflineLimitWarningType.normal;

  /// Нужно ли показать диалог премиум
  bool get shouldShowPremiumDialog => warningType == OfflineLimitWarningType.blocked;

  /// Цвет индикатора для UI
  Color get indicatorColor {
    switch (warningType) {
      case OfflineLimitWarningType.normal:
        return Colors.green;
      case OfflineLimitWarningType.approaching:
        return Colors.orange;
      case OfflineLimitWarningType.overLimit:
        return Colors.red;
      case OfflineLimitWarningType.blocked:
        return Colors.red.shade800;
    }
  }

  /// Иконка для UI
  IconData get indicatorIcon {
    switch (warningType) {
      case OfflineLimitWarningType.normal:
        return Icons.check_circle;
      case OfflineLimitWarningType.approaching:
        return Icons.warning;
      case OfflineLimitWarningType.overLimit:
        return Icons.error;
      case OfflineLimitWarningType.blocked:
        return Icons.block;
    }
  }

  /// Процент использования
  double get usagePercentage {
    if (limit == 0) return 0.0;
    return (currentUsage / limit).clamp(0.0, 1.0);
  }

  /// Процент использования с учетом grace period
  double get usagePercentageWithGrace {
    final totalLimit = limit + SubscriptionConstants.offlineGraceLimit;
    if (totalLimit == 0) return 0.0;
    return (currentUsage / totalLimit).clamp(0.0, 1.0);
  }

  /// Превышен ли базовый лимит
  bool get isOverBaseLimit => currentUsage > limit;

  /// Количество элементов сверх лимита
  int get overageCount => isOverBaseLimit ? currentUsage - limit : 0;

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

  /// Преобразование в Map для логирования
  Map<String, dynamic> toMap() {
    return {
      'canCreate': canCreate,
      'warningType': warningType.name,
      'message': message,
      'currentUsage': currentUsage,
      'limit': limit,
      'remaining': remaining,
      'contentType': contentType.name,
      'isOverBaseLimit': isOverBaseLimit,
      'overageCount': overageCount,
      'usagePercentage': usagePercentage,
    };
  }

  @override
  String toString() {
    return 'OfflineUsageResult(canCreate: $canCreate, warningType: $warningType, currentUsage: $currentUsage, limit: $limit, remaining: $remaining, contentType: $contentType)';
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