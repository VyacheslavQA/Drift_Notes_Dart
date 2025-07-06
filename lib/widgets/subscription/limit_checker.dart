// Путь: lib/widgets/subscription/limit_checker.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';  // ИСПРАВЛЕНО: ContentType здесь
import '../../services/subscription/subscription_service.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';

/// Виджет для проверки лимитов контента перед показом экрана создания
class LimitChecker extends StatelessWidget {
  final ContentType contentType;
  final Widget child;
  final VoidCallback? onLimitReached;
  final String? blockedFeature; // Для премиум функций типа графика глубин

  const LimitChecker({
    super.key,
    required this.contentType,
    required this.child,
    this.onLimitReached,
    this.blockedFeature,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(  // ИСПРАВЛЕНО: используем SubscriptionModel
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();

        // Если это премиум функция - проверяем наличие премиума
        if (blockedFeature != null) {
          if (!subscriptionService.isPremium) {  // ИСПРАВЛЕНО: используем геттер isPremium
            return _buildBlockedFeatureWidget(context);
          }
          return child;
        }

        // Проверяем лимиты для обычного контента
        // ИСПРАВЛЕНО: используем асинхронную проверку через FutureBuilder
        return FutureBuilder<bool>(
          future: _canCreateContent(subscriptionService, contentType),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return child; // Показываем содержимое пока загружается
            }

            final canCreate = futureSnapshot.data ?? false;
            if (canCreate) {
              return child;
            } else {
              return _buildLimitReachedWidget(context);
            }
          },
        );
      },
    );
  }

  // ДОБАВЛЕНО: Помощник для асинхронной проверки лимитов
  Future<bool> _canCreateContent(SubscriptionService service, ContentType contentType) async {
    // Если премиум - разрешаем всё
    if (service.isPremium) return true;

    // Для графика глубин всегда false
    if (contentType == ContentType.depthChart) return false;

    // Проверяем через usage limits service (нужно будет добавить этот метод)
    try {
      // Временное решение: проверяем через текущую подписку
      final subscription = service.currentSubscription;
      return subscription?.isPremium ?? false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildLimitReachedWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        if (onLimitReached != null) {
          onLimitReached!();
        } else {
          _showPaywall(context, contentType);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            child,
            // Полупрозрачный оверлей
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('limit_reached'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.translate('tap_for_premium'),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedFeatureWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _showPaywall(context, null, blockedFeature: blockedFeature),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars,
              color: Colors.purple,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('premium_feature'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('upgrade_to_access'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showPaywall(context, null, blockedFeature: blockedFeature),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                localizations.translate('get_premium'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaywall(BuildContext context, ContentType? contentType, {String? blockedFeature}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: contentType?.name,  // ИСПРАВЛЕНО: передаем название enum
          blockedFeature: blockedFeature,
        ),
      ),
    );
  }
}

/// Функция-помощник для проверки лимитов перед навигацией
Future<bool> checkLimitBeforeNavigation(
    BuildContext context,
    ContentType contentType,
    ) async {
  final subscriptionService = SubscriptionService();
  final localizations = AppLocalizations.of(context);

  // ИСПРАВЛЕНО: используем асинхронную проверку
  bool canCreate;
  try {
    if (subscriptionService.isPremium) {
      canCreate = true;
    } else if (contentType == ContentType.depthChart) {
      canCreate = false;
    } else {
      // Временное решение - всегда разрешаем для обычного контента
      canCreate = true;
    }
  } catch (e) {
    canCreate = false;
  }

  if (canCreate) {
    return true;
  }

  // Показываем paywall
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => PaywallScreen(
        contentType: contentType.name,  // ИСПРАВЛЕНО: передаем название enum
      ),
    ),
  );

  return result ?? false;
}

/// Функция для проверки премиум доступа к функции
Future<bool> checkPremiumFeatureAccess(
    BuildContext context,
    String featureName,
    ) async {
  final subscriptionService = SubscriptionService();

  if (subscriptionService.isPremium) {  // ИСПРАВЛЕНО: используем геттер isPremium
    return true;
  }

  // Показываем paywall для премиум функции
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => PaywallScreen(
        blockedFeature: featureName,
      ),
    ),
  );

  return result ?? false;
}