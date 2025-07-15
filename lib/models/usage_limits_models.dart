// Путь: lib/models/usage_limits_models.dart

import '../constants/subscription_constants.dart';

/// Результат проверки возможности создания контента
class ContentCreationResult {
  final bool canCreate;
  final ContentCreationBlockReason? reason;
  final int currentCount;
  final int limit;
  final int remaining;

  const ContentCreationResult({
    required this.canCreate,
    this.reason,
    required this.currentCount,
    required this.limit,
    required this.remaining,
  });

  @override
  String toString() {
    return 'ContentCreationResult(canCreate: $canCreate, current: $currentCount/$limit, remaining: $remaining)';
  }
}

/// Причины блокировки создания контента
enum ContentCreationBlockReason {
  limitReached,      // Достигнут лимит
  premiumRequired,   // Требуется премиум подписка
  error,            // Ошибка при проверке
}

/// Предупреждение о достижении лимита
class ContentTypeWarning {
  final ContentType contentType;
  final int currentCount;
  final int limit;
  final int remaining;
  final double percentage;

  const ContentTypeWarning({
    required this.contentType,
    required this.currentCount,
    required this.limit,
    required this.remaining,
    required this.percentage,
  });

  @override
  String toString() {
    return 'ContentTypeWarning($contentType: ${(percentage * 100).toInt()}% used, $remaining remaining)';
  }
}