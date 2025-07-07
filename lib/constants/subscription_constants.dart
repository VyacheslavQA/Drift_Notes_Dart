// Путь: lib/constants/subscription_constants.dart

import 'dart:io';
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
  // FIREBASE КОНФИГУРАЦИЯ
  // ========================================

  static const String subscriptionCollection = 'subscriptions';
  static const String usageLimitsCollection = 'usage_limits';

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