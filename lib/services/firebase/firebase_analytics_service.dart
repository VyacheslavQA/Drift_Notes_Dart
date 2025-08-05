// Путь: lib/services/firebase/firebase_analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../constants/subscription_constants.dart';

/// 🎯 Сервис аналитики для Drift Notes
/// Отслеживает ключевые события для принятия бизнес-решений
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ========================================
  // 🔐 ИНИЦИАЛИЗАЦИЯ И ПОЛЬЗОВАТЕЛИ
  // ========================================

  /// Инициализация аналитики
  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('🎯 Firebase Analytics инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации Analytics: $e');
    }
  }

  /// Установка пользователя после авторизации
  Future<void> setUser(String userId, {
    String? email,
    String? authMethod,
    bool? isPremium,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      // Устанавливаем пользовательские свойства
      await _analytics.setUserProperty(
          name: 'auth_method',
          value: authMethod ?? 'unknown'
      );

      if (isPremium != null) {
        await _analytics.setUserProperty(
            name: 'subscription_status',
            value: isPremium ? 'premium' : 'free'
        );
      }

      debugPrint('👤 Пользователь установлен: $userId, метод: $authMethod');
    } catch (e) {
      debugPrint('❌ Ошибка установки пользователя: $e');
    }
  }

  // ========================================
  // 🔑 АВТОРИЗАЦИЯ
  // ========================================

  /// Вход в приложение
  Future<void> trackLogin(String method, {bool? success}) async {
    try {
      await _analytics.logLogin(loginMethod: method);

      await _analytics.logEvent(
        name: 'user_login_attempt',
        parameters: {
          'method': method,
          'success': success ?? true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🔑 Логин отслежен: $method, успех: $success');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания логина: $e');
    }
  }

  /// Переход в офлайн режим
  Future<void> trackOfflineMode(bool enabled) async {
    try {
      await _analytics.logEvent(
        name: 'offline_mode_toggle',
        parameters: {
          'enabled': enabled,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📱 Офлайн режим: $enabled');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания офлайн режима: $e');
    }
  }

  // ========================================
  // 📝 СОЗДАНИЕ КОНТЕНТА
  // ========================================

  /// Создание заметки рыбалки
  Future<void> trackFishingNoteCreated({
    required String fishingType,
    required bool isMultiDay,
    required int photosCount,
    required int biteRecordsCount,
    bool? hasWeather,
    bool? hasAIPrediction,
    bool? hasLocation,
    int? tripDays,
  }) async {
    try {
      debugPrint('🎯 Отправляем событие: fishing_note_created');

      await _analytics.logEvent(
        name: 'fishing_note_created',
        parameters: {
          'fishing_type': fishingType,
          'is_multi_day': isMultiDay ? 'true' : 'false', // ✅ ИСПРАВЛЕНО: boolean → string
          'photos_count': photosCount,
          'bite_records_count': biteRecordsCount,
          'has_weather': (hasWeather ?? false) ? 'true' : 'false', // ✅ ИСПРАВЛЕНО
          'has_ai_prediction': (hasAIPrediction ?? false) ? 'true' : 'false', // ✅ ИСПРАВЛЕНО
          'has_location': (hasLocation ?? false) ? 'true' : 'false', // ✅ ИСПРАВЛЕНО
          'trip_days': tripDays ?? 1,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📝 Заметка рыбалки создана: $fishingType, фото: $photosCount, поклевки: $biteRecordsCount');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания создания заметки: $e');
    }
  }

  /// Создание маркерной карты
  Future<void> trackMarkerMapCreated({
    required int markersCount,
    required String mapTitle,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'marker_map_created',
        parameters: {
          'markers_count': markersCount,
          'map_title': mapTitle,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🗺️ Маркерная карта создана: $markersCount маркеров');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания создания карты: $e');
    }
  }

  /// Добавление маркера на карту
  Future<void> trackMarkerAdded({
    required String bottomType,
    required double depth,
    required double distance,
    required int rayIndex,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'marker_added',
        parameters: {
          'bottom_type': bottomType,
          'depth': depth,
          'distance': distance,
          'ray_index': rayIndex,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📍 Маркер добавлен: $bottomType, глубина: $depth');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания добавления маркера: $e');
    }
  }

  /// Создание расходов на рыбалку
  Future<void> trackBudgetNoteCreated({
    required int categoriesCount,
    required double totalAmount,
    required String currency,
    required bool isMultiDay,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'budget_note_created',
        parameters: {
          'categories_count': categoriesCount,
          'total_amount': totalAmount,
          'currency': currency,
          'is_multi_day': isMultiDay,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('💰 Расходы созданы: $categoriesCount категорий, $totalAmount $currency');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания создания расходов: $e');
    }
  }

  // ========================================
  // 🤖 ИСПОЛЬЗОВАНИЕ ФУНКЦИЙ
  // ========================================

  /// Использование ИИ анализа
  Future<void> trackAIAnalysisUsed({
    required String fishingType,
    required int overallScore,
    required String activityLevel,
    required int confidencePercent,
    bool? success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_analysis_used',
        parameters: {
          'fishing_type': fishingType,
          'overall_score': overallScore,
          'activity_level': activityLevel,
          'confidence_percent': confidencePercent,
          'success': success ?? true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🤖 ИИ анализ: $fishingType, скор: $overallScore, уверенность: $confidencePercent%');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания ИИ анализа: $e');
    }
  }

  /// Загрузка погоды
  Future<void> trackWeatherLoaded({
    required double latitude,
    required double longitude,
    required double temperature,
    required String weatherDescription,
    bool? success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'weather_loaded',
        parameters: {
          'latitude': latitude,
          'longitude': longitude,
          'temperature': temperature,
          'weather_description': weatherDescription,
          'success': success ?? true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🌤️ Погода загружена: $temperature°C, $weatherDescription');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания погоды: $e');
    }
  }

  /// Добавление фото
  Future<void> trackPhotoAdded({
    required String source, // 'camera' или 'gallery'
    required double originalSizeMB,
    required double compressedSizeMB,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'photo_added',
        parameters: {
          'source': source,
          'original_size_mb': originalSizeMB,
          'compressed_size_mb': compressedSizeMB,
          'compression_ratio': originalSizeMB > 0 ? compressedSizeMB / originalSizeMB : 1.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📸 Фото добавлено: $source, $originalSizeMB MB → $compressedSizeMB MB');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания добавления фото: $e');
    }
  }

  /// Запись поклевки
  Future<void> trackBiteRecorded({
    required String fishType,
    required double weight,
    required double length,
    required int dayIndex,
    bool? hasCatch,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'bite_recorded',
        parameters: {
          'fish_type': fishType,
          'weight': weight,
          'length': length,
          'day_index': dayIndex,
          'has_catch': hasCatch ?? (weight > 0),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🎣 Поклевка записана: $fishType, вес: $weight кг');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания поклевки: $e');
    }
  }

  // ========================================
  // 💎 ПРЕМИУМ ФУНКЦИИ
  // ========================================

  /// Доступ к премиум функции
  Future<void> trackPremiumFeatureAccessed({
    required String featureName,
    required bool hasAccess,
    String? blockedReason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'premium_feature_accessed',
        parameters: {
          'feature_name': featureName,
          'has_access': hasAccess,
          'blocked_reason': blockedReason ?? (hasAccess ? null : 'no_subscription'),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('💎 Премиум функция: $featureName, доступ: $hasAccess');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания премиум функции: $e');
    }
  }

  /// Использование графиков глубины
  Future<void> trackDepthChartsUsed({
    required int markersCount,
    required bool hasAccess,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'depth_charts_used',
        parameters: {
          'markers_count': markersCount,
          'has_access': hasAccess,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📊 Графики глубины: $markersCount маркеров, доступ: $hasAccess');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания графиков глубины: $e');
    }
  }

  // ========================================
  // 💰 МОНЕТИЗАЦИЯ
  // ========================================

  /// Показ Paywall экрана
  Future<void> trackPaywallShown({
    required String reason,
    required String contentType,
    required String blockedFeature,
    int? currentUsage,
    int? maxLimit,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'paywall_shown',
        parameters: {
          'reason': reason,
          'content_type': contentType,
          'blocked_feature': blockedFeature,
          'current_usage': currentUsage,
          'max_limit': maxLimit,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🚫 Paywall показан: $reason, контент: $contentType');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания paywall: $e');
    }
  }

  /// Начало покупки подписки
  Future<void> trackSubscriptionPurchaseStarted({
    required String productId,
    required String planType, // 'monthly' или 'yearly'
    required String price,
    String? currency,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_purchase_started',
        parameters: {
          'product_id': productId,
          'plan_type': planType,
          'price': price,
          'currency': currency ?? 'USD',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('💳 Покупка начата: $planType, цена: $price');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания начала покупки: $e');
    }
  }

  /// Результат покупки подписки
  Future<void> trackSubscriptionPurchaseCompleted({
    required String productId,
    required String planType,
    required bool success,
    String? errorReason,
    String? price,
    double? yearlyDiscount,
  }) async {
    try {
      if (success) {
        // Firebase предустановленное событие для успешной покупки
        await _analytics.logPurchase(
          currency: 'USD', // можно изменить на реальную валюту
          value: _extractPriceValue(price ?? '0'),
          items: [
            AnalyticsEventItem(
              itemId: productId,
              itemName: 'Premium Subscription',
              itemCategory: planType,
              price: _extractPriceValue(price ?? '0'),
              quantity: 1,
            ),
          ],
        );
      }

      await _analytics.logEvent(
        name: 'subscription_purchase_completed',
        parameters: {
          'product_id': productId,
          'plan_type': planType,
          'success': success,
          'error_reason': errorReason,
          'price': price,
          'yearly_discount': yearlyDiscount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('✅ Покупка завершена: $planType, успех: $success');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания завершения покупки: $e');
    }
  }

  /// Восстановление покупок
  Future<void> trackPurchasesRestored({
    required bool success,
    int? restoredCount,
    String? errorReason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'purchases_restored',
        parameters: {
          'success': success,
          'restored_count': restoredCount ?? 0,
          'error_reason': errorReason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🔄 Покупки восстановлены: успех: $success, количество: $restoredCount');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания восстановления покупок: $e');
    }
  }

  // ========================================
  // 📊 ЛИМИТЫ И ИСПОЛЬЗОВАНИЕ
  // ========================================

  /// Проверка лимита
  Future<void> trackLimitCheck({
    required String contentType,
    required int currentUsage,
    required int maxLimit,
    required bool canProceed,
    required bool isPremium,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'limit_check',
        parameters: {
          'content_type': contentType,
          'current_usage': currentUsage,
          'max_limit': maxLimit,
          'can_proceed': canProceed,
          'is_premium': isPremium,
          'usage_percentage': maxLimit > 0 ? (currentUsage / maxLimit * 100).round() : 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📏 Лимит проверен: $contentType, $currentUsage/$maxLimit, разрешено: $canProceed');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания проверки лимита: $e');
    }
  }

  /// Достижение лимита
  Future<void> trackLimitReached({
    required String contentType,
    required int maxLimit,
    required bool isPremium,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'limit_reached',
        parameters: {
          'content_type': contentType,
          'max_limit': maxLimit,
          'is_premium': isPremium,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🚫 Лимит достигнут: $contentType, максимум: $maxLimit');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания достижения лимита: $e');
    }
  }

  // ========================================
  // 🎯 БИЗНЕС-МЕТРИКИ
  // ========================================

  /// Статистика использования (еженедельный отчет)
  Future<void> trackUsageStats({
    required int totalNotes,
    required int totalMaps,
    required int totalBudgetNotes,
    required bool isPremium,
    required int daysActive,
    String? mostUsedFishingType,
    String? mostUsedCurrency,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'weekly_usage_stats',
        parameters: {
          'total_notes': totalNotes,
          'total_maps': totalMaps,
          'total_budget_notes': totalBudgetNotes,
          'is_premium': isPremium,
          'days_active': daysActive,
          'most_used_fishing_type': mostUsedFishingType,
          'most_used_currency': mostUsedCurrency,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('📈 Статистика: заметки: $totalNotes, карты: $totalMaps, расходы: $totalBudgetNotes');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания статистики: $e');
    }
  }

  /// Пользователь стал премиум
  Future<void> trackUserBecamePremium({
    required String planType,
    required String price,
    required int daysFromInstall,
    required int totalNotesCreated,
    required int totalMapsCreated,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_became_premium',
        parameters: {
          'plan_type': planType,
          'price': price,
          'days_from_install': daysFromInstall,
          'total_notes_created': totalNotesCreated,
          'total_maps_created': totalMapsCreated,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('🎉 Пользователь стал премиум: $planType, дней с установки: $daysFromInstall');
    } catch (e) {
      debugPrint('❌ Ошибка отслеживания становления премиум: $e');
    }
  }

  // ========================================
  // 🛠️ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Извлечение числового значения из строки цены
  double _extractPriceValue(String priceString) {
    try {
      final numericString = priceString.replaceAll(RegExp(r'[^\d.,]'), '');
      final cleanString = numericString.replaceAll(',', '.');
      return double.parse(cleanString);
    } catch (e) {
      debugPrint('⚠️ Не удалось извлечь цену из: $priceString');
      return 0.0;
    }
  }

  /// Получение строкового представления ContentType
  String _getContentTypeString(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'fishing_notes';
      case ContentType.markerMaps:
        return 'marker_maps';
      case ContentType.budgetNotes:
        return 'budget_notes';
      case ContentType.depthChart:
        return 'depth_chart';
    }
  }

  // ========================================
  // 🎯 УДОБНЫЕ МЕТОДЫ ДЛЯ ИНТЕГРАЦИИ
  // ========================================

  /// Отслеживание лимита с автоматическим определением типа
  Future<void> trackLimitCheckForContentType({
    required ContentType contentType,
    required int currentUsage,
    required int maxLimit,
    required bool canProceed,
    required bool isPremium,
  }) async {
    await trackLimitCheck(
      contentType: _getContentTypeString(contentType),
      currentUsage: currentUsage,
      maxLimit: maxLimit,
      canProceed: canProceed,
      isPremium: isPremium,
    );

    // Если лимит достигнут - дополнительно отслеживаем
    if (!canProceed && !isPremium) {
      await trackLimitReached(
        contentType: _getContentTypeString(contentType),
        maxLimit: maxLimit,
        isPremium: isPremium,
      );
    }
  }

  /// Быстрое отслеживание paywall с лимитами
  Future<void> trackPaywallForLimits({
    required ContentType contentType,
    required String blockedFeature,
    required int currentUsage,
    required int maxLimit,
  }) async {
    await trackPaywallShown(
      reason: 'limit_exceeded',
      contentType: _getContentTypeString(contentType),
      blockedFeature: blockedFeature,
      currentUsage: currentUsage,
      maxLimit: maxLimit,
    );
  }
}