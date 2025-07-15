// Путь: lib/models/subscription_model.dart

import '../constants/subscription_constants.dart';

/// ✅ ИСПРАВЛЕННАЯ модель подписки пользователя
/// Использует правильные константы из SubscriptionConstants
class SubscriptionModel {
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionType? type;
  final DateTime? expirationDate;
  final String? purchaseToken;
  final String platform; // 'android', 'ios' или 'unknown'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // ✅ НОВЫЕ поля для полной поддержки подписки
  final String? productId;
  final String? originalTransactionId;
  final DateTime? lastValidation;
  final bool autoRenew;

  const SubscriptionModel({
    required this.userId,
    required this.status,
    this.type,
    this.expirationDate,
    this.purchaseToken,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.productId,
    this.originalTransactionId,
    this.lastValidation,
    this.autoRenew = true,
  });

  /// ✅ УПРОЩЕННАЯ фабрика: подписка по умолчанию (нет подписки)
  factory SubscriptionModel.defaultSubscription(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      userId: userId,
      status: SubscriptionStatus.none,
      type: null,
      expirationDate: null,
      purchaseToken: null,
      platform: SubscriptionConstants.getCurrentPlatform(),
      createdAt: now,
      updatedAt: now,
      isActive: false,
      productId: null,
      originalTransactionId: null,
      lastValidation: null,
      autoRenew: false,
    );
  }

  /// ✅ ИСПРАВЛЕНО: Создание из Map с правильными константами
  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String userId) {
    final status = _parseStatus(map[SubscriptionConstants.subscriptionStatusField]);
    final expirationDate = _parseDateTime(map[SubscriptionConstants.subscriptionExpirationField]);

    return SubscriptionModel(
      userId: userId,
      status: status,
      type: _parseType(map[SubscriptionConstants.subscriptionPlanField]),
      expirationDate: expirationDate,
      purchaseToken: map[SubscriptionConstants.subscriptionPurchaseTokenField],
      platform: map[SubscriptionConstants.subscriptionPlatformField] ??
          SubscriptionConstants.getCurrentPlatform(),
      createdAt: _parseDateTime(map[SubscriptionConstants.subscriptionCreatedAtField]) ??
          DateTime.now(),
      updatedAt: _parseDateTime(map[SubscriptionConstants.subscriptionUpdatedAtField]) ??
          DateTime.now(),
      isActive: _calculateIsActive(status, expirationDate),
      productId: map[SubscriptionConstants.subscriptionProductIdField],
      originalTransactionId: map[SubscriptionConstants.subscriptionOriginalTransactionIdField],
      lastValidation: _parseDateTime(map[SubscriptionConstants.subscriptionLastValidationField]),
      autoRenew: map[SubscriptionConstants.subscriptionAutoRenewField] ?? true,
    );
  }

  /// ✅ ИСПРАВЛЕНО: Преобразование в Map с правильными константами
  Map<String, dynamic> toMap() {
    return {
      SubscriptionConstants.subscriptionStatusField: status.name,
      SubscriptionConstants.subscriptionPlanField: type?.name,
      SubscriptionConstants.subscriptionExpirationField: expirationDate?.toIso8601String(),
      SubscriptionConstants.subscriptionPurchaseTokenField: purchaseToken,
      SubscriptionConstants.subscriptionPlatformField: platform,
      SubscriptionConstants.subscriptionCreatedAtField: createdAt.toIso8601String(),
      SubscriptionConstants.subscriptionUpdatedAtField: updatedAt.toIso8601String(),
      SubscriptionConstants.subscriptionProductIdField: productId,
      SubscriptionConstants.subscriptionOriginalTransactionIdField: originalTransactionId,
      SubscriptionConstants.subscriptionLastValidationField: lastValidation?.toIso8601String(),
      SubscriptionConstants.subscriptionAutoRenewField: autoRenew,
    };
  }

  /// ✅ ОБНОВЛЕННОЕ копирование с новыми полями
  SubscriptionModel copyWith({
    String? userId,
    SubscriptionStatus? status,
    SubscriptionType? type,
    DateTime? expirationDate,
    String? purchaseToken,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? productId,
    String? originalTransactionId,
    DateTime? lastValidation,
    bool? autoRenew,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      type: type ?? this.type,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      productId: productId ?? this.productId,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
      lastValidation: lastValidation ?? this.lastValidation,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  /// ✅ УЛУЧШЕННАЯ проверка активности подписки
  bool get isPremium => isActive && (status == SubscriptionStatus.active);

  /// Проверка истекает ли подписка скоро (в течение 3 дней)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiration = expirationDate!.difference(now).inDays;
    return daysUntilExpiration <= 3 && daysUntilExpiration >= 0;
  }

  /// Получение количества дней до истечения
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    final difference = expirationDate!.difference(now).inDays;
    return difference >= 0 ? difference : 0;
  }

  /// ✅ УЛУЧШЕННОЕ получение названия плана
  String get planDisplayName {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Месячная подписка';
      case SubscriptionType.yearly:
        return 'Годовая подписка';
      case null:
        return 'Бесплатный план';
    }
  }

  /// ✅ ПРАВИЛЬНОЕ получение Product ID
  String? get currentProductId {
    // Приоритет: сохраненный productId, затем вычисленный из типа
    if (productId != null && SubscriptionConstants.isValidProductId(productId!)) {
      return productId;
    }

    if (type != null) {
      return SubscriptionConstants.getProductId(type!);
    }

    return null;
  }

  /// ✅ НОВОЕ: Проверка валидности подписки
  bool get isValid {
    return status == SubscriptionStatus.active &&
        expirationDate != null &&
        DateTime.now().isBefore(expirationDate!) &&
        isActive;
  }

  /// ✅ НОВОЕ: Нужно ли обновить валидацию
  bool get needsValidation {
    if (lastValidation == null) return true;

    // Обновляем валидацию каждые 24 часа
    final hoursSinceValidation = DateTime.now().difference(lastValidation!).inHours;
    return hoursSinceValidation >= 24;
  }

  /// ✅ НОВОЕ: Статус для UI
  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.none:
        return 'Нет подписки';
      case SubscriptionStatus.active:
        return 'Активна';
      case SubscriptionStatus.expired:
        return 'Истекла';
      case SubscriptionStatus.canceled:
        return 'Отменена';
      case SubscriptionStatus.pending:
        return 'Ожидает активации';
    }
  }

  /// ✅ НОВОЕ: Создание активной подписки
  factory SubscriptionModel.createActiveSubscription({
    required String userId,
    required SubscriptionType type,
    required DateTime expirationDate,
    required String purchaseToken,
    String? productId,
    String? originalTransactionId,
  }) {
    final now = DateTime.now();
    final platform = SubscriptionConstants.getCurrentPlatform();
    final finalProductId = productId ?? SubscriptionConstants.getProductId(type);

    return SubscriptionModel(
      userId: userId,
      status: SubscriptionStatus.active,
      type: type,
      expirationDate: expirationDate,
      purchaseToken: purchaseToken,
      platform: platform,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      productId: finalProductId,
      originalTransactionId: originalTransactionId,
      lastValidation: now,
      autoRenew: true,
    );
  }

  // ========================================
  // ✅ ПРИВАТНЫЕ МЕТОДЫ ДЛЯ ПАРСИНГА
  // ========================================

  static SubscriptionStatus _parseStatus(dynamic value) {
    if (value == null) return SubscriptionStatus.none;

    try {
      return SubscriptionStatus.values.firstWhere(
            (status) => status.name == value.toString(),
        orElse: () => SubscriptionStatus.none,
      );
    } catch (e) {
      return SubscriptionStatus.none;
    }
  }

  static SubscriptionType? _parseType(dynamic value) {
    if (value == null) return null;

    try {
      return SubscriptionType.values.firstWhere(
            (type) => type.name == value.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        return DateTime.parse(value);
      }

      // Для Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        // Используем рефлексию для вызова toDate()
        return (value as dynamic).toDate() as DateTime;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _calculateIsActive(
      SubscriptionStatus status,
      DateTime? expirationDate,
      ) {
    if (status != SubscriptionStatus.active) {
      return false;
    }

    if (expirationDate == null) return false;

    return DateTime.now().isBefore(expirationDate);
  }

  @override
  String toString() {
    return 'SubscriptionModel('
        'userId: $userId, '
        'status: $status, '
        'type: $type, '
        'expirationDate: $expirationDate, '
        'platform: $platform, '
        'isActive: $isActive, '
        'productId: $productId'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionModel &&
        other.userId == userId &&
        other.status == status &&
        other.type == type &&
        other.expirationDate == expirationDate &&
        other.purchaseToken == purchaseToken &&
        other.platform == platform &&
        other.isActive == isActive &&
        other.productId == productId &&
        other.originalTransactionId == originalTransactionId;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      status,
      type,
      expirationDate,
      purchaseToken,
      platform,
      isActive,
      productId,
      originalTransactionId,
    );
  }
}