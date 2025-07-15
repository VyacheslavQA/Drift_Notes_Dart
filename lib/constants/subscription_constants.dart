// Путь: lib/constants/subscription_constants.dart

import 'dart:io';
import 'package:flutter/material.dart';

// ========================================
// ОСНОВНЫЕ ЕНУМЫ
// ========================================

/// Типы подписки
enum SubscriptionType {
  monthly,
  yearly,
}

/// Статус подписки
enum SubscriptionStatus {
  none,          // Нет подписки
  active,        // Активная подписка
  expired,       // Истекшая подписка
  canceled,      // Отмененная подписка
  pending,       // Ожидающая активации
}

/// 🔥 ИСПРАВЛЕНО: expenses → budgetNotes
enum ContentType {
  fishingNotes,
  markerMaps,
  budgetNotes,   // ✅ ИСПРАВЛЕНО! Было expenses
  depthChart,    // Полностью заблокирован без подписки
}

/// 🔥 УПРОЩЕНО: Только 3 основные валюты вместо 5
enum SupportedCurrency {
  rub,    // Российские рубли (основная)
  kzt,    // Казахстанские тенге
  usd,    // Доллары США (фоллбэк)
}

class SubscriptionConstants {
  // ========================================
  // GOOGLE PLAY PRODUCT IDs
  // ========================================

  static const String monthlyPremiumId = 'drift_notes_monthly_premium';
  static const String yearlyPremiumId = 'drift_notes_yearly_premium';

  static const List<String> subscriptionProductIds = [
    monthlyPremiumId,
    yearlyPremiumId,
  ];

  // ========================================
  // 🔥 УПРОЩЕННАЯ СИСТЕМА ЦЕН (3 валюты вместо 5)
  // ========================================

  static const Map<SupportedCurrency, Map<String, String>> pricesByRegion = {
    // Россия и СНГ
    SupportedCurrency.rub: {
      monthlyPremiumId: '₽299',
      yearlyPremiumId: '₽2490',
    },

    // Казахстан
    SupportedCurrency.kzt: {
      monthlyPremiumId: '₸1490',
      yearlyPremiumId: '₸11990',
    },

    // Международные пользователи (фоллбэк)
    SupportedCurrency.usd: {
      monthlyPremiumId: '\$4.99',
      yearlyPremiumId: '\$39.99',
    },
  };

  // 🔥 УПРОЩЕНО: Определение валюты только для основных регионов
  static const Map<String, SupportedCurrency> countryToCurrency = {
    'RU': SupportedCurrency.rub,  // Россия
    'BY': SupportedCurrency.rub,  // Беларусь
    'KZ': SupportedCurrency.kzt,  // Казахстан
    // Все остальные страны → USD
  };

  // ========================================
  // 🔥 УПРОЩЕННЫЕ ЛИМИТЫ (без grace period)
  // ========================================

  static const int freeNotesLimit = 3;
  static const int freeMarkerMapsLimit = 3;
  static const int freeBudgetNotesLimit = 3;
  static const int unlimitedValue = 999999;// ✅ ИСПРАВЛЕНО! Было freeExpensesLimit

  // ========================================
  // 🔥 ИСПРАВЛЕННАЯ FIREBASE СТРУКТУРА
  // ========================================

  // Новая структура: users/{userId}/subcollections
  static const String usersCollection = 'users';
  static const String userUsageLimitsSubcollection = 'usage_limits';
  static const String currentUsageLimitsDocument = 'current';

  // Subcollections для заметок
  static const String fishingNotesSubcollection = 'fishing_notes';
  static const String budgetNotesSubcollection = 'budget_notes';    // ✅ ИСПРАВЛЕНО! Было expenses
  static const String markerMapsSubcollection = 'marker_maps';
  static const String subscriptionSubcollection = 'subscription';

  // ========================================
  // ✅ ДОБАВЛЕНЫ НЕДОСТАЮЩИЕ ПОЛЯ ПОДПИСКИ
  // ========================================

  // Основные поля подписки
  static const String subscriptionStatusField = 'status';
  static const String subscriptionPlanField = 'plan';
  static const String subscriptionExpirationField = 'expirationDate';
  static const String subscriptionCreatedAtField = 'createdAt';
  static const String subscriptionUpdatedAtField = 'updatedAt';

  // ✅ НОВЫЕ поля для полной поддержки подписки
  static const String subscriptionPurchaseTokenField = 'purchaseToken';
  static const String subscriptionPlatformField = 'platform';
  static const String subscriptionProductIdField = 'productId';
  static const String subscriptionOriginalTransactionIdField = 'originalTransactionId';
  static const String subscriptionLastValidationField = 'lastValidation';
  static const String subscriptionAutoRenewField = 'autoRenew';

  // ✅ КОНСТАНТЫ ПЛАТФОРМ
  static const String androidPlatform = 'android';
  static const String iosPlatform = 'ios';
  static const String unknownPlatform = 'unknown';

  // Поля лимитов использования
  static const String notesCountField = 'notesCount';
  static const String markerMapsCountField = 'markerMapsCount';
  static const String budgetNotesCountField = 'budgetNotesCount';  // ✅ ИСПРАВЛЕНО! Было expensesCount
  static const String lastResetDateField = 'lastResetDate';

  // Общие поля
  static const String userIdField = 'userId';
  static const String updatedAtField = 'updatedAt';
  static const String createdAtField = 'createdAt';

  // ========================================
  // 🔥 УПРОЩЕННЫЕ МЕТОДЫ ПУТЕЙ FIREBASE
  // ========================================

  /// Путь к документу лимитов пользователя
  static String getUserUsageLimitsPath(String userId) {
    return '$usersCollection/$userId/$userUsageLimitsSubcollection/$currentUsageLimitsDocument';
  }

  /// Путь к subcollection заметок рыбалки
  static String getFishingNotesPath(String userId) {
    return '$usersCollection/$userId/$fishingNotesSubcollection';
  }

  /// Путь к subcollection заметок бюджета
  static String getBudgetNotesPath(String userId) {
    return '$usersCollection/$userId/$budgetNotesSubcollection';
  }

  /// Путь к subcollection маркерных карт
  static String getMarkerMapsPath(String userId) {
    return '$usersCollection/$userId/$markerMapsSubcollection';
  }

  /// Путь к subcollection подписки
  static String getSubscriptionPath(String userId) {
    return '$usersCollection/$userId/$subscriptionSubcollection';
  }

  /// ✅ НОВЫЙ: Путь к конкретному документу подписки
  static String getSubscriptionDocumentPath(String userId, [String documentId = 'current']) {
    return '$usersCollection/$userId/$subscriptionSubcollection/$documentId';
  }

  // ========================================
  // 🔥 УПРОЩЕННЫЕ МЕТОДЫ ЛИМИТОВ (без grace period)
  // ========================================

  /// Простая проверка превышения лимита
  static bool isOverLimit(int currentUsage, int limit) {
    return currentUsage >= limit;
  }

  /// Получение лимита для типа контента
  static int getContentLimit(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return freeNotesLimit;
      case ContentType.markerMaps:
        return freeMarkerMapsLimit;
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return freeBudgetNotesLimit;
      case ContentType.depthChart:
        return 0; // Только для премиум
    }
  }

  /// Получение поля Firebase для типа контента
  static String getFirebaseCountField(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return notesCountField;
      case ContentType.markerMaps:
        return markerMapsCountField;
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return budgetNotesCountField;
      case ContentType.depthChart:
        return 'depthChartCount';
    }
  }

  /// Получение пути к subcollection для типа контента
  static String getContentSubcollectionPath(String userId, ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return getFishingNotesPath(userId);
      case ContentType.markerMaps:
        return getMarkerMapsPath(userId);
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses
        return getBudgetNotesPath(userId);
      case ContentType.depthChart:
        return '$usersCollection/$userId/depth_charts'; // Премиум функция
    }
  }

  /// Проверка является ли контент премиум функцией
  static bool isContentPremium(ContentType contentType) {
    return contentType == ContentType.depthChart;
  }

  /// Можно ли создать контент (простая проверка)
  static bool canCreate(int currentUsage, int limit) {
    return currentUsage < limit;
  }

  /// Получение названия типа контента для UI
  static String getContentTypeName(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'заметок рыбалки';
      case ContentType.markerMaps:
        return 'маркерных карт';
      case ContentType.budgetNotes:  // ✅ ИСПРАВЛЕНО! Было expenses → поездок
        return 'заметок бюджета';
      case ContentType.depthChart:
        return 'графиков глубины';
    }
  }

  /// Получение цвета индикатора лимита
  static Color getLimitIndicatorColor(int currentUsage, int limit) {
    final percentage = limit > 0 ? currentUsage / limit : 0.0;

    if (percentage >= 1.0) return Colors.red;           // 100% - красный
    if (percentage >= 0.8) return Colors.orange;        // 80%+ - оранжевый
    if (percentage >= 0.6) return Colors.yellow;        // 60%+ - желтый
    return Colors.green;                                 // <60% - зеленый
  }

  // ========================================
  // ✅ НОВЫЕ МЕТОДЫ ДЛЯ ПОДПИСКИ
  // ========================================

  /// Получение текущей платформы
  static String getCurrentPlatform() {
    try {
      if (Platform.isAndroid) return androidPlatform;
      if (Platform.isIOS) return iosPlatform;
      return unknownPlatform;
    } catch (e) {
      return unknownPlatform;
    }
  }

  /// Валидация Product ID
  static bool isValidProductId(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  /// Получение типа подписки по Product ID
  static SubscriptionType? getSubscriptionTypeFromProductId(String productId) {
    switch (productId) {
      case monthlyPremiumId:
        return SubscriptionType.monthly;
      case yearlyPremiumId:
        return SubscriptionType.yearly;
      default:
        return null;
    }
  }

  // ========================================
  // 🔥 УПРОЩЕННЫЕ МЕТОДЫ РАБОТЫ С ВАЛЮТАМИ
  // ========================================

  /// Получение валюты пользователя (упрощенная логика)
  static Future<SupportedCurrency> getUserCurrency() async {
    try {
      final String? locale = Platform.localeName;

      if (locale != null && locale.length >= 5) {
        final String countryCode = locale.substring(3, 5).toUpperCase();

        if (countryToCurrency.containsKey(countryCode)) {
          return countryToCurrency[countryCode]!;
        }
      }

      // Фоллбэк по языку
      if (locale != null && locale.startsWith('ru')) {
        return SupportedCurrency.rub;
      } else if (locale != null && locale.startsWith('kk')) {
        return SupportedCurrency.kzt;
      }

      return SupportedCurrency.usd;
    } catch (e) {
      return SupportedCurrency.usd;
    }
  }

  /// Получение цен для текущего пользователя
  static Future<Map<String, String>> getLocalizedPrices() async {
    final currency = await getUserCurrency();
    return pricesByRegion[currency] ?? pricesByRegion[SupportedCurrency.usd]!;
  }

  /// Получение символа валюты
  static String getCurrencySymbol(SupportedCurrency currency) {
    switch (currency) {
      case SupportedCurrency.rub:
        return '₽';
      case SupportedCurrency.kzt:
        return '₸';
      case SupportedCurrency.usd:
        return '\$';
    }
  }

  // ========================================
  // БАЗОВЫЕ МЕТОДЫ (без изменений)
  // ========================================

  static String getProductId(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return monthlyPremiumId;
      case SubscriptionType.yearly:
        return yearlyPremiumId;
    }
  }

  static SubscriptionType? getSubscriptionType(String productId) {
    switch (productId) {
      case monthlyPremiumId:
        return SubscriptionType.monthly;
      case yearlyPremiumId:
        return SubscriptionType.yearly;
      default:
        return null;
    }
  }

  static bool isValidProduct(String productId) {
    return subscriptionProductIds.contains(productId);
  }

  /// Фоллбэк цены
  static const Map<String, String> defaultPrices = {
    monthlyPremiumId: '\$4.99',
    yearlyPremiumId: '\$39.99',
  };

  static String getDefaultPrice(String productId) {
    return defaultPrices[productId] ?? '\$4.99';
  }
}