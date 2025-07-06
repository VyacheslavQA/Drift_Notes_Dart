// Путь: lib/models/subscription_model.dart

import 'dart:io';
import '../constants/subscription_constants.dart';

/// Модель подписки пользователя
class SubscriptionModel {
  final String userId;
  final SubscriptionStatus status;
  final SubscriptionType? type;
  final DateTime? expirationDate;
  final String? purchaseToken;
  final String platform; // 'android' или 'ios'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

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
  });

  /// Создание подписки по умолчанию (нет подписки)
  factory SubscriptionModel.defaultSubscription(String userId) {
    final now = DateTime.now();
    return SubscriptionModel(
      userId: userId,
      status: SubscriptionStatus.none,
      type: null,
      expirationDate: null,
      purchaseToken: null,
      platform: _getCurrentPlatform(),
      createdAt: now,
      updatedAt: now,
      isActive: false,
    );
  }

  /// Создание из Map (для Firebase)
  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String userId) {
    return SubscriptionModel(
      userId: userId,
      status: _parseStatus(map[SubscriptionConstants.subscriptionStatusField]),
      type: _parseType(map[SubscriptionConstants.subscriptionPlanField]),
      expirationDate: _parseDateTime(map[SubscriptionConstants.subscriptionExpirationField]),
      purchaseToken: map[SubscriptionConstants.subscriptionPurchaseTokenField],
      platform: map[SubscriptionConstants.subscriptionPlatformField] ?? _getCurrentPlatform(),
      createdAt: _parseDateTime(map[SubscriptionConstants.subscriptionCreatedAtField]) ?? DateTime.now(),
      updatedAt: _parseDateTime(map[SubscriptionConstants.subscriptionUpdatedAtField]) ?? DateTime.now(),
      isActive: _calculateIsActive(
        _parseStatus(map[SubscriptionConstants.subscriptionStatusField]),
        _parseDateTime(map[SubscriptionConstants.subscriptionExpirationField]),
      ),
    );
  }

  /// Преобразование в Map (для Firebase)
  Map<String, dynamic> toMap() {
    return {
      SubscriptionConstants.subscriptionStatusField: status.name,
      SubscriptionConstants.subscriptionPlanField: type?.name,
      SubscriptionConstants.subscriptionExpirationField: expirationDate?.toIso8601String(),
      SubscriptionConstants.subscriptionPurchaseTokenField: purchaseToken,
      SubscriptionConstants.subscriptionPlatformField: platform,
      SubscriptionConstants.subscriptionCreatedAtField: createdAt.toIso8601String(),
      SubscriptionConstants.subscriptionUpdatedAtField: updatedAt.toIso8601String(),
    };
  }

  /// Копирование с изменениями
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
    );
  }

  /// Проверка активности подписки
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

  /// Получение названия плана
  String get planDisplayName {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Monthly Premium';
      case SubscriptionType.yearly:
        return 'Yearly Premium';
      case null:
        return 'Free';
    }
  }

  /// Получение Product ID
  String? get productId {
    if (type == null) return null;
    return SubscriptionConstants.getProductId(type!);
  }

  // Приватные методы для парсинга

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
      if (value.toString().contains('Timestamp')) {
        // Предполагаем что это Firestore Timestamp
        return value.toDate();
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

  static String _getCurrentPlatform() {
    try {
      // Определяем платформу
      if (Platform.isAndroid) {
        return SubscriptionConstants.androidPlatform;
      } else if (Platform.isIOS) {
        return SubscriptionConstants.iosPlatform;
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  String toString() {
    return 'SubscriptionModel('
        'userId: $userId, '
        'status: $status, '
        'type: $type, '
        'expirationDate: $expirationDate, '
        'platform: $platform, '
        'isActive: $isActive'
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
        other.isActive == isActive;
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
    );
  }
}