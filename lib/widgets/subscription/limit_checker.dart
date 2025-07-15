// Путь: lib/widgets/subscription/limit_checker.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';

/// ✅ УПРОЩЕННЫЙ виджет для проверки лимитов контента перед показом экрана создания
class LimitChecker extends StatefulWidget {
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
  State<LimitChecker> createState() => _LimitCheckerState();
}

class _LimitCheckerState extends State<LimitChecker> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _canCreate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  /// ✅ ИСПРАВЛЕНО: Проверка доступа через новую Firebase систему
  Future<void> _checkAccess() async {
    try {
      // Если это премиум функция - проверяем наличие премиума
      if (widget.blockedFeature != null) {
        final hasPremium = _subscriptionService.hasPremiumAccess();

        if (mounted) {
          setState(() {
            _canCreate = hasPremium;
            _isLoading = false;
          });
        }
        return;
      }

      // Если премиум пользователь - разрешаем всё
      if (_subscriptionService.hasPremiumAccess()) {
        if (mounted) {
          setState(() {
            _canCreate = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Для графика глубин - только премиум
      if (widget.contentType == ContentType.depthChart) {
        if (mounted) {
          setState(() {
            _canCreate = false;
            _isLoading = false;
          });
        }
        return;
      }

      // ✅ ИСПРАВЛЕНО: Проверяем лимиты через новую Firebase систему
      final firebaseKey = SubscriptionConstants.getFirebaseCountField(widget.contentType);
      final limitCheck = await _firebaseService.canCreateItem(firebaseKey);
      final canCreate = limitCheck['canProceed'] ?? false;

      if (mounted) {
        setState(() {
          _canCreate = canCreate;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ LimitChecker: Ошибка проверки доступа: $e');

      if (mounted) {
        setState(() {
          _canCreate = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: _subscriptionService.subscriptionStream,
      builder: (context, snapshot) {
        if (_isLoading) {
          return widget.child; // Показываем содержимое пока загружается
        }

        // Если это премиум функция и нет премиума - показываем блокировку
        if (widget.blockedFeature != null && !_canCreate) {
          return _buildBlockedFeatureWidget(context);
        }

        // Если лимиты превышены - показываем блокировку
        if (!_canCreate) {
          return _buildLimitReachedWidget(context);
        }

        // Всё в порядке - показываем содержимое
        return widget.child;
      },
    );
  }

  Widget _buildLimitReachedWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        if (widget.onLimitReached != null) {
          widget.onLimitReached!();
        } else {
          _showPaywall(context, widget.contentType);
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
            widget.child,
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
                    const Icon(
                      Icons.lock,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('limit_reached') ?? 'Лимит достигнут',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.translate('tap_for_premium') ?? 'Нажмите для премиум',
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
      onTap: () => _showPaywall(context, null, blockedFeature: widget.blockedFeature),
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
            const Icon(
              Icons.stars,
              color: Colors.purple,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('premium_feature') ?? 'Премиум функция',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('upgrade_to_access') ?? 'Обновитесь для доступа',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showPaywall(context, null, blockedFeature: widget.blockedFeature),
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
                localizations.translate('get_premium') ?? 'Получить премиум',
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
          contentType: contentType?.name,
          blockedFeature: blockedFeature,
        ),
      ),
    );
  }
}

/// ✅ ИСПРАВЛЕНО: Функция-помощник для проверки лимитов перед навигацией
Future<bool> checkLimitBeforeNavigation(
    BuildContext context,
    ContentType contentType,
    ) async {
  final subscriptionService = SubscriptionService();
  final firebaseService = FirebaseService();

  try {
    // Если премиум - разрешаем всё
    if (subscriptionService.hasPremiumAccess()) {
      return true;
    }

    // Для графика глубин - только премиум
    if (contentType == ContentType.depthChart) {
      await _showPaywallForContentType(context, contentType);
      return false;
    }

    // ✅ ИСПРАВЛЕНО: Используем константу для получения Firebase ключа
    final firebaseKey = SubscriptionConstants.getFirebaseCountField(contentType);
    final limitCheck = await firebaseService.canCreateItem(firebaseKey);
    final canCreate = limitCheck['canProceed'] ?? false;

    if (canCreate) {
      return true;
    }

    // Показываем paywall
    await _showPaywallForContentType(context, contentType);
    return false;
  } catch (e) {
    debugPrint('❌ Ошибка проверки лимитов перед навигацией: $e');

    // При ошибке показываем paywall
    await _showPaywallForContentType(context, contentType);
    return false;
  }
}

/// ✅ УПРОЩЕНО: Функция для проверки премиум доступа к функции
Future<bool> checkPremiumFeatureAccess(
    BuildContext context,
    String featureName,
    ) async {
  final subscriptionService = SubscriptionService();

  if (subscriptionService.hasPremiumAccess()) {
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

/// Помощник для показа paywall
Future<bool> _showPaywallForContentType(
    BuildContext context,
    ContentType contentType,
    ) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => PaywallScreen(
        contentType: contentType.name,
      ),
    ),
  );

  return result ?? false;
}