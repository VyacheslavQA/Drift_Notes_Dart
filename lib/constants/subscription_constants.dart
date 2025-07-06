// Путь: lib/constants/subscription_constants.dart

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

class SubscriptionConstants {
  // Идентификаторы продуктов (должны совпадать с App Store Connect и Google Play Console)
  static const String monthlyPremiumId = 'monthly_premium';
  static const String yearlyPremiumId = 'yearly_premium';

  // Список всех продуктов подписки
  static const List<String> subscriptionProductIds = [
    monthlyPremiumId,
    yearlyPremiumId,
  ];

  // Лимиты для бесплатной версии
  static const int freeNotesLimit = 3;
  static const int freeMarkerMapsLimit = 3;
  static const int freeExpensesLimit = 3;

  // ДОБАВЛЕНО: Константа для безлимитного доступа
  static const int unlimitedValue = 999999;

  // Ключи для локализации
  static const String subscriptionTitle = 'premium_subscription';
  static const String monthlyPlanTitle = 'monthly_plan';
  static const String yearlyPlanTitle = 'yearly_plan';
  static const String upgradeButton = 'upgrade_to_premium';
  static const String restorePurchases = 'restore_purchases';

  // Ключи для SharedPreferences (кэширование)
  static const String cachedSubscriptionStatusKey = 'cached_subscription_status';
  static const String cachedExpirationDateKey = 'cached_expiration_date';
  static const String cachedPlanTypeKey = 'cached_plan_type';

  // Ключи для Firestore
  static const String subscriptionCollection = 'subscriptions';
  static const String usageLimitsCollection = 'usage_limits';

  // Firebase документ структура
  static const String subscriptionStatusField = 'status';
  static const String subscriptionPlanField = 'plan';
  static const String subscriptionExpirationField = 'expirationDate';
  static const String subscriptionPurchaseTokenField = 'purchaseToken';
  static const String subscriptionPlatformField = 'platform';
  static const String subscriptionCreatedAtField = 'createdAt';
  static const String subscriptionUpdatedAtField = 'updatedAt';

  // Лимиты использования
  static const String notesCountField = 'notesCount';
  static const String markerMapsCountField = 'markerMapsCount';
  static const String expensesCountField = 'expensesCount';
  static const String lastResetDateField = 'lastResetDate';

  // Платформы
  static const String androidPlatform = 'android';
  static const String iosPlatform = 'ios';

  // Периоды сброса лимитов (если нужно в будущем)
  static const Duration limitResetPeriod = Duration(days: 30);

  // Цены по умолчанию (для отображения если не удалось загрузить из магазина)
  static const Map<String, String> defaultPrices = {
    monthlyPremiumId: '\$4.99',
    yearlyPremiumId: '\$39.99',
  };

  // Получение локализованного названия плана
  static String getPlanLocalizedKey(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return monthlyPlanTitle;
      case SubscriptionType.yearly:
        return yearlyPlanTitle;
    }
  }

  // Получение продукта по типу подписки
  static String getProductId(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return monthlyPremiumId;
      case SubscriptionType.yearly:
        return yearlyPremiumId;
    }
  }

  // Получение типа подписки по продукту
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

  // Проверка является ли контент премиум
  static bool isContentPremium(ContentType contentType) {
    switch (contentType) {
      case ContentType.depthChart:
        return true; // График глубин полностью заблокирован
      case ContentType.fishingNotes:
      case ContentType.markerMaps:
      case ContentType.expenses:
        return false; // Эти имеют лимиты, но не полностью заблокированы
    }
  }

  // Получение лимита для типа контента
  static int getContentLimit(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return freeNotesLimit;
      case ContentType.markerMaps:
        return freeMarkerMapsLimit;
      case ContentType.expenses:
        return freeExpensesLimit;
      case ContentType.depthChart:
        return 0; // Полностью заблокирован
    }
  }
}