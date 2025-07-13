// Путь: lib/constants/subscription_constants.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Типы подписки (вынесены наружу из класса)
enum SubscriptionType {
  monthly,
  yearly,
}

// Статус подписки (вынесены наружу из класса)
enum SubscriptionStatus {
  none,          // Нет подписки
  active,        // Активная подписка
  expired,       // Истекшая подписка
  canceled,      // Отмененная подписка
  pending,       // Ожидающая активации
}

// Типы контента с ограничениями (вынесены наружу из класса)
enum ContentType {
  fishingNotes,
  markerMaps,
  expenses,
  depthChart,    // Полностью заблокирован без подписки
}

// ДОБАВЛЕНО: Поддерживаемые валюты и регионы
enum SupportedCurrency {
  usd,    // Доллары США
  rub,    // Российские рубли
  kzt,    // Казахстанские тенге
  eur,    // Евро
  uah,    // Украинские гривны
}

// 🔥 НОВЫЕ ЕНУМЫ для офлайн режима

/// Типы предупреждений о лимитах в офлайн режиме
enum OfflineLimitWarningType {
  normal,       // Нормальное использование
  approaching,  // Приближение к лимиту
  overLimit,    // Превышение лимита (но в рамках grace period)
  blocked,      // Критическое превышение - блокировка
}

/// Статус кэша подписки
enum CacheStatus {
  trusted,    // Доверенный кэш (до 30 дней)
  warning,    // Предупреждение (30-60 дней)
  expired,    // Истекший (60-90 дней)
  invalid,    // Недействительный (более 90 дней)
}

class SubscriptionConstants {
  // ========================================
  // GOOGLE PLAY PRODUCT IDs
  // ========================================

  // Базовые ID продуктов (будут использоваться для всех регионов)
  static const String monthlyPremiumId = 'drift_notes_monthly_premium';
  static const String yearlyPremiumId = 'drift_notes_yearly_premium';

  // Список всех продуктов подписки
  static const List<String> subscriptionProductIds = [
    monthlyPremiumId,
    yearlyPremiumId,
  ];

  // ========================================
  // GOOGLE PLAY ТЕСТОВЫЕ IDs
  // ========================================

  static const String testMonthlyId = 'android.test.purchased';
  static const String testYearlyId = 'android.test.item_unavailable';

  static const List<String> testProductIds = [
    testMonthlyId,
    testYearlyId,
  ];

  // ========================================
  // МУЛЬТИВАЛЮТНАЯ СИСТЕМА ЦЕН
  // ========================================

  // Цены для разных стран/валют
  static const Map<SupportedCurrency, Map<String, String>> pricesByRegion = {
    // США и международные пользователи
    SupportedCurrency.usd: {
      monthlyPremiumId: '\$4.99',
      yearlyPremiumId: '\$39.99',
    },

    // Россия
    SupportedCurrency.rub: {
      monthlyPremiumId: '₽299',
      yearlyPremiumId: '₽2490',  // ~17% скидка
    },

    // Казахстан
    SupportedCurrency.kzt: {
      monthlyPremiumId: '₸1490',
      yearlyPremiumId: '₸11990', // ~20% скидка
    },

    // Европа
    SupportedCurrency.eur: {
      monthlyPremiumId: '€4.49',
      yearlyPremiumId: '€35.99',
    },

    // Украина
    SupportedCurrency.uah: {
      monthlyPremiumId: '₴149',
      yearlyPremiumId: '₴1199',
    },
  };

  // Определение валюты по коду страны
  static const Map<String, SupportedCurrency> countryToCurrency = {
    'RU': SupportedCurrency.rub,  // Россия
    'KZ': SupportedCurrency.kzt,  // Казахстан
    'BY': SupportedCurrency.rub,  // Беларусь (используем рубли)
    'UA': SupportedCurrency.uah,  // Украина
    'DE': SupportedCurrency.eur,  // Германия
    'FR': SupportedCurrency.eur,  // Франция
    'IT': SupportedCurrency.eur,  // Италия
    'ES': SupportedCurrency.eur,  // Испания
    'US': SupportedCurrency.usd,  // США
    'CA': SupportedCurrency.usd,  // Канада (используем доллары)
    'GB': SupportedCurrency.eur,  // Великобритания (используем евро)
  };

  // ========================================
  // ЛИМИТЫ И ОГРАНИЧЕНИЯ
  // ========================================

  static const int freeNotesLimit = 3;
  static const int freeMarkerMapsLimit = 3;
  static const int freeExpensesLimit = 3;
  static const int unlimitedValue = 999999;

  // 🔥 НОВЫЕ КОНСТАНТЫ для офлайн режима

  /// Офлайн режим - количество дополнительных элементов сверх лимита
  static const int offlineGraceLimit = 3;

  /// Кэширование подписки - дни полного доверия к кэшу
  static const int cacheTrustDays = 30;

  /// Кэширование подписки - дни с предупреждением о проверке
  static const int cacheWarningDays = 60;

  /// Кэширование подписки - полное истечение кэша
  static const int cacheExpireDays = 90;

  /// Время действия кэша использования (в минутах)
  static const int usageCacheMinutes = 5;

  /// Максимальное количество попыток синхронизации
  static const int maxSyncRetries = 3;

  /// Задержка между попытками синхронизации (в секундах)
  static const int syncRetryDelaySeconds = 5;

  // ========================================
  // ЛОКАЛИЗАЦИЯ И КЭШИРОВАНИЕ
  // ========================================

  static const String subscriptionTitle = 'premium_subscription';
  static const String monthlyPlanTitle = 'monthly_plan';
  static const String yearlyPlanTitle = 'yearly_plan';
  static const String upgradeButton = 'upgrade_to_premium';
  static const String restorePurchases = 'restore_purchases';

  static const String cachedSubscriptionStatusKey = 'cached_subscription_status';
  static const String cachedExpirationDateKey = 'cached_expiration_date';
  static const String cachedPlanTypeKey = 'cached_plan_type';
  static const String cachedCurrencyKey = 'cached_user_currency';

  // ========================================
  // 🔥 FIREBASE КОНФИГУРАЦИЯ - ОБНОВЛЕНО ДЛЯ НОВОЙ СТРУКТУРЫ
  // ========================================

  static const String subscriptionCollection = 'subscriptions';

  // 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Убираем старую константу usage_limits!
  // static const String usageLimitsCollection = 'usage_limits'; // ❌ УДАЛЕНО - СТАРАЯ СТРУКТУРА

  // 🔥 НОВЫЕ КОНСТАНТЫ для новой структуры users/{userId}/usage_limits/current
  static const String usersCollection = 'users';
  static const String userUsageLimitsSubcollection = 'usage_limits';
  static const String currentUsageLimitsDocument = 'current';

  static const String subscriptionStatusField = 'status';
  static const String subscriptionPlanField = 'plan';
  static const String subscriptionExpirationField = 'expirationDate';
  static const String subscriptionPurchaseTokenField = 'purchaseToken';
  static const String subscriptionPlatformField = 'platform';
  static const String subscriptionCreatedAtField = 'createdAt';
  static const String subscriptionUpdatedAtField = 'updatedAt';

  static const String notesCountField = 'notesCount';
  static const String markerMapsCountField = 'markerMapsCount';
  static const String expensesCountField = 'expensesCount';
  static const String lastResetDateField = 'lastResetDate';

  static const String androidPlatform = 'android';
  static const String iosPlatform = 'ios';

  static const Duration limitResetPeriod = Duration(days: 30);

  // 🔥 НОВЫЕ КОНСТАНТЫ для Firebase операций
  static const String userIdField = 'userId';
  static const String updatedAtField = 'updatedAt';
  static const String createdAtField = 'createdAt';

  // ========================================
  // 🔥 НОВЫЕ МЕТОДЫ для построения путей Firebase
  // ========================================

  /// Получить путь к документу лимитов пользователя в новой структуре
  static String getUserUsageLimitsPath(String userId) {
    return '$usersCollection/$userId/$userUsageLimitsSubcollection/$currentUsageLimitsDocument';
  }

  /// Получить референс коллекции users
  static String getUsersCollectionPath() {
    return usersCollection;
  }

  /// Получить путь к subcollection лимитов пользователя
  static String getUserUsageLimitsSubcollectionPath(String userId) {
    return '$usersCollection/$userId/$userUsageLimitsSubcollection';
  }

  /// Получить путь к документу пользователя
  static String getUserDocumentPath(String userId) {
    return '$usersCollection/$userId';
  }

  // ========================================
  // 🔥 НОВЫЕ МЕТОДЫ для офлайн режима
  // ========================================

  /// Проверка превышения лимита с учетом офлайн режима
  static bool isOverLimitWithGrace(int currentUsage, int limit) {
    return currentUsage >= (limit + offlineGraceLimit);
  }

  /// Получение оставшихся дополнительных элементов
  static int getRemainingGraceElements(int currentUsage, int limit) {
    if (currentUsage <= limit) {
      return offlineGraceLimit;
    }

    final used = currentUsage - limit;
    return (offlineGraceLimit - used).clamp(0, offlineGraceLimit);
  }

  /// Проверка критического превышения лимита
  static bool isCriticalOverage(int currentUsage, int limit) {
    return currentUsage >= (limit + offlineGraceLimit);
  }

  /// Проверка приближения к лимиту
  static bool isApproachingLimit(int currentUsage, int limit) {
    return currentUsage >= (limit - 2); // За 2 элемента до лимита
  }

  /// Проверка превышения базового лимита
  static bool isOverBaseLimit(int currentUsage, int limit) {
    return currentUsage > limit;
  }

  /// Получение типа предупреждения о лимите
  static OfflineLimitWarningType getWarningType(int currentUsage, int limit) {
    if (isCriticalOverage(currentUsage, limit)) {
      return OfflineLimitWarningType.blocked;
    }

    if (isOverBaseLimit(currentUsage, limit)) {
      return OfflineLimitWarningType.overLimit;
    }

    if (isApproachingLimit(currentUsage, limit)) {
      return OfflineLimitWarningType.approaching;
    }

    return OfflineLimitWarningType.normal;
  }

  /// Получение сообщения о статусе лимита
  static String getLimitStatusMessage(int currentUsage, int limit, ContentType contentType) {
    final warningType = getWarningType(currentUsage, limit);
    final contentName = getContentTypeName(contentType);

    switch (warningType) {
      case OfflineLimitWarningType.blocked:
        return 'Лимит $contentName исчерпан. Требуется Premium подписка.';

      case OfflineLimitWarningType.overLimit:
        final remaining = getRemainingGraceElements(currentUsage, limit);
        return 'Использовано ${currentUsage - limit} из $offlineGraceLimit дополнительных $contentName. Осталось: $remaining.';

      case OfflineLimitWarningType.approaching:
        final remaining = limit - currentUsage;
        return 'Осталось $remaining $contentName до лимита.';

      case OfflineLimitWarningType.normal:
        return 'Использовано $currentUsage из $limit $contentName.';
    }
  }

  /// Получение названия типа контента
  static String getContentTypeName(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'заметок';
      case ContentType.markerMaps:
        return 'карт';
      case ContentType.expenses:
        return 'поездок';
      case ContentType.depthChart:
        return 'графиков глубины';
    }
  }

  /// Проверка актуальности кэша по времени
  static bool isCacheValid(DateTime cacheTime, int validDays) {
    final now = DateTime.now();
    final daysSinceCache = now.difference(cacheTime).inDays;
    return daysSinceCache < validDays;
  }

  /// Получение статуса кэша
  static CacheStatus getCacheStatus(DateTime cacheTime) {
    final now = DateTime.now();
    final daysSinceCache = now.difference(cacheTime).inDays;

    if (daysSinceCache < cacheTrustDays) {
      return CacheStatus.trusted;
    } else if (daysSinceCache < cacheWarningDays) {
      return CacheStatus.warning;
    } else if (daysSinceCache < cacheExpireDays) {
      return CacheStatus.expired;
    } else {
      return CacheStatus.invalid;
    }
  }

  /// Получение цвета для индикатора лимита
  static Color getLimitIndicatorColor(int currentUsage, int limit) {
    final warningType = getWarningType(currentUsage, limit);

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

  /// Получение иконки для индикатора лимита
  static IconData getLimitIndicatorIcon(int currentUsage, int limit) {
    final warningType = getWarningType(currentUsage, limit);

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

  /// Получение процента использования
  static double getUsagePercentage(int currentUsage, int limit) {
    if (limit == 0) return 0.0;
    return (currentUsage / limit).clamp(0.0, 1.0);
  }

  /// Получение процента использования с учетом grace period
  static double getUsagePercentageWithGrace(int currentUsage, int limit) {
    final totalLimit = limit + offlineGraceLimit;
    if (totalLimit == 0) return 0.0;
    return (currentUsage / totalLimit).clamp(0.0, 1.0);
  }

  /// Проверка необходимости показа предупреждения
  static bool shouldShowWarning(int currentUsage, int limit) {
    return getWarningType(currentUsage, limit) != OfflineLimitWarningType.normal;
  }

  /// Проверка необходимости показа диалога премиум
  static bool shouldShowPremiumDialog(int currentUsage, int limit) {
    return getWarningType(currentUsage, limit) == OfflineLimitWarningType.blocked;
  }

  /// Получение заголовка для диалога превышения лимита
  static String getLimitDialogTitle(ContentType contentType) {
    final contentName = getContentTypeName(contentType);
    return 'Лимит $contentName превышен';
  }

  /// Получение описания для диалога превышения лимита
  static String getLimitDialogDescription(ContentType contentType, int currentUsage, int limit) {
    final contentName = getContentTypeName(contentType);
    final remaining = getRemainingGraceElements(currentUsage, limit);

    if (isCriticalOverage(currentUsage, limit)) {
      return 'Вы превысили лимит на ${currentUsage - limit} $contentName. Для продолжения использования требуется Premium подписка.';
    } else if (isOverBaseLimit(currentUsage, limit)) {
      return 'Вы превысили базовый лимит на ${currentUsage - limit} $contentName. Осталось $remaining дополнительных элементов.';
    } else {
      return 'Приближается лимит использования $contentName.';
    }
  }

  // ========================================
  // МЕТОДЫ ДЛЯ РАБОТЫ С ВАЛЮТАМИ
  // ========================================

  /// Получение валюты пользователя по локали устройства
  static Future<SupportedCurrency> getUserCurrency() async {
    try {
      // Получаем локаль устройства
      final String? locale = Platform.localeName; // 'ru_RU', 'en_US', 'kk_KZ'

      if (locale != null && locale.length >= 5) {
        final String countryCode = locale.substring(3, 5).toUpperCase();

        // Проверяем есть ли страна в нашей карте
        if (countryToCurrency.containsKey(countryCode)) {
          return countryToCurrency[countryCode]!;
        }
      }

      // Фоллбэк: пытаемся определить по языку
      if (locale != null && locale.startsWith('ru')) {
        return SupportedCurrency.rub;
      } else if (locale != null && locale.startsWith('kk')) {
        return SupportedCurrency.kzt;
      }

      // По умолчанию возвращаем доллары
      return SupportedCurrency.usd;

    } catch (e) {
      // В случае ошибки возвращаем доллары
      return SupportedCurrency.usd;
    }
  }

  /// Получение цен для текущего пользователя
  static Future<Map<String, String>> getLocalizedPrices() async {
    final currency = await getUserCurrency();
    return pricesByRegion[currency] ?? pricesByRegion[SupportedCurrency.usd]!;
  }

  /// Получение цены конкретного продукта для пользователя
  static Future<String> getLocalizedPrice(String productId) async {
    final prices = await getLocalizedPrices();
    return prices[productId] ?? '\$4.99'; // Фоллбэк
  }

  /// Получение символа валюты
  static String getCurrencySymbol(SupportedCurrency currency) {
    switch (currency) {
      case SupportedCurrency.usd:
        return '\$';
      case SupportedCurrency.rub:
        return '₽';
      case SupportedCurrency.kzt:
        return '₸';
      case SupportedCurrency.eur:
        return '€';
      case SupportedCurrency.uah:
        return '₴';
    }
  }

  /// Получение названия валюты
  static String getCurrencyName(SupportedCurrency currency) {
    switch (currency) {
      case SupportedCurrency.usd:
        return 'USD';
      case SupportedCurrency.rub:
        return 'RUB';
      case SupportedCurrency.kzt:
        return 'KZT';
      case SupportedCurrency.eur:
        return 'EUR';
      case SupportedCurrency.uah:
        return 'UAH';
    }
  }

  /// Расчет скидки для годового плана (в зависимости от валюты)
  static double getYearlyDiscount(SupportedCurrency currency) {
    switch (currency) {
      case SupportedCurrency.rub:
      // ₽299 * 12 = ₽3588, ₽2490 = ~31% скидка
        return 31.0;
      case SupportedCurrency.kzt:
      // ₸1490 * 12 = ₸17880, ₸11990 = ~33% скидка
        return 33.0;
      case SupportedCurrency.usd:
      // $4.99 * 12 = $59.88, $39.99 = ~33% скидка
        return 33.0;
      case SupportedCurrency.eur:
      // €4.49 * 12 = €53.88, €35.99 = ~33% скидка
        return 33.0;
      case SupportedCurrency.uah:
      // ₴149 * 12 = ₴1788, ₴1199 = ~33% скидка
        return 33.0;
    }
  }

  /// Получение скидки для текущего пользователя
  static Future<double> getUserYearlyDiscount() async {
    final currency = await getUserCurrency();
    return getYearlyDiscount(currency);
  }

  // ========================================
  // СУЩЕСТВУЮЩИЕ МЕТОДЫ (без изменений)
  // ========================================

  static String getPlanLocalizedKey(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return monthlyPlanTitle;
      case SubscriptionType.yearly:
        return yearlyPlanTitle;
    }
  }

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
      case testMonthlyId:
        return SubscriptionType.monthly;
      case yearlyPremiumId:
      case testYearlyId:
        return SubscriptionType.yearly;
      default:
        return null;
    }
  }

  static bool isContentPremium(ContentType contentType) {
    switch (contentType) {
      case ContentType.depthChart:
        return true;
      case ContentType.fishingNotes:
      case ContentType.markerMaps:
      case ContentType.expenses:
        return false;
    }
  }

  static int getContentLimit(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return freeNotesLimit;
      case ContentType.markerMaps:
        return freeMarkerMapsLimit;
      case ContentType.expenses:
        return freeExpensesLimit;
      case ContentType.depthChart:
        return 0;
    }
  }

  // ========================================
  // ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ
  // ========================================

  /// Проверка является ли продукт тестовым
  static bool isTestProduct(String productId) {
    return testProductIds.contains(productId);
  }

  /// Получение списка продуктов для режима разработки
  static List<String> getProductIds({bool useTestProducts = false}) {
    return useTestProducts ? testProductIds : subscriptionProductIds;
  }

  /// Валидация продукта
  static bool isValidProduct(String productId) {
    return subscriptionProductIds.contains(productId) ||
        testProductIds.contains(productId);
  }

  /// Получение периода подписки в днях
  static int getSubscriptionPeriodDays(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.yearly:
        return 365;
    }
  }

  // ========================================
  // ОБРАТНАЯ СОВМЕСТИМОСТЬ
  // ========================================

  /// Фоллбэк цены (для обратной совместимости)
  static const Map<String, String> defaultPrices = {
    monthlyPremiumId: '\$4.99',
    yearlyPremiumId: '\$39.99',
  };

  /// Получение фоллбэк цены
  static String getDefaultPrice(String productId) {
    return defaultPrices[productId] ?? '\$4.99';
  }
}