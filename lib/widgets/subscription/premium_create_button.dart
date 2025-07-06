// Путь: lib/widgets/subscription/premium_create_button.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';
import '../../constants/app_constants.dart';
import 'usage_badge.dart';

/// Кнопка создания контента с автоматической проверкой лимитов
class PremiumCreateButton extends StatelessWidget {
  final ContentType contentType;
  final VoidCallback onCreatePressed;
  final String? customText;
  final IconData? customIcon;
  final bool showUsageBadge;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final EdgeInsets? padding;
  final bool isFloatingActionButton;

  const PremiumCreateButton({
    super.key,
    required this.contentType,
    required this.onCreatePressed,
    this.customText,
    this.customIcon,
    this.showUsageBadge = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
    this.padding,
    this.isFloatingActionButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();
        final localizations = AppLocalizations.of(context);

        // ИСПРАВЛЕНО: используем FutureBuilder для асинхронной проверки
        return FutureBuilder<bool>(
          future: subscriptionService.canCreateContent(contentType),
          builder: (context, futureSnapshot) {
            final canCreate = futureSnapshot.data ?? false; // По умолчанию запрещаем

            if (isFloatingActionButton) {
              return _buildFloatingActionButton(
                context,
                canCreate,
                localizations,
                subscriptionService,
              );
            }

            return _buildRegularButton(
              context,
              canCreate,
              localizations,
              subscriptionService,
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton(
      BuildContext context,
      bool canCreate,
      AppLocalizations localizations,
      SubscriptionService subscriptionService,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showUsageBadge && !subscriptionService.hasPremiumAccess()) ...[
          CompactUsageBadge(
            contentType: contentType,
            showOnlyWhenNearLimit: true,
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: canCreate
              ? () => _handleCreatePress(context, subscriptionService)
              : () => _showPaywall(context),
          backgroundColor: canCreate
              ? (backgroundColor ?? AppConstants.primaryColor)
              : Colors.grey.withOpacity(0.7),
          foregroundColor: canCreate
              ? (foregroundColor ?? Colors.white)
              : Colors.white70,
          child: Stack(
            children: [
              Icon(
                canCreate
                    ? (customIcon ?? Icons.add)
                    : Icons.lock,
                size: 28,
              ),
              if (!canCreate)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularButton(
      BuildContext context,
      bool canCreate,
      AppLocalizations localizations,
      SubscriptionService subscriptionService,
      ) {
    final buttonText = _getButtonText(localizations, canCreate);
    final buttonIcon = _getButtonIcon(canCreate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: canCreate
              ? () => _handleCreatePress(context, subscriptionService)
              : () => _showPaywall(context),
          icon: Icon(buttonIcon),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showUsageBadge)
                UsageBadge(
                  contentType: contentType,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canCreate
                ? (backgroundColor ?? AppConstants.primaryColor)
                : Colors.grey.withOpacity(0.5),
            foregroundColor: canCreate
                ? (foregroundColor ?? Colors.white)
                : Colors.white70,
            padding: padding ?? const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              side: !canCreate
                  ? const BorderSide(color: Colors.orange, width: 2)
                  : BorderSide.none,
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        if (!canCreate) ...[
          const SizedBox(height: 8),
          _buildLimitWarning(context, localizations, subscriptionService),
        ],
      ],
    );
  }

  Widget _buildLimitWarning(
      BuildContext context,
      AppLocalizations localizations,
      SubscriptionService subscriptionService,
      ) {
    final currentUsage = subscriptionService.getCurrentUsage(contentType);
    final limit = subscriptionService.getLimit(contentType);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${localizations.translate('limit_reached_description')} ($currentUsage/$limit)',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showPaywall(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              localizations.translate('upgrade_now'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ДОБАВЛЕНО: Обработчик нажатия с увеличением счетчика использования
  Future<void> _handleCreatePress(
      BuildContext context,
      SubscriptionService subscriptionService,
      ) async {
    // Увеличиваем счетчик использования (если не премиум)
    if (!subscriptionService.hasPremiumAccess()) {
      final success = await subscriptionService.incrementUsage(contentType);
      if (!success) {
        // Если не удалось увеличить (превышен лимит), показываем paywall
        _showPaywall(context);
        return;
      }
    }

    // Вызываем оригинальный колбэк
    onCreatePressed();
  }

  String _getButtonText(AppLocalizations localizations, bool canCreate) {
    if (customText != null) return customText!;

    if (!canCreate) {
      return localizations.translate('limit_reached_short');
    }

    switch (contentType) {
      case ContentType.fishingNotes:
        return localizations.translate('create_fishing_note');
      case ContentType.markerMaps:
        return localizations.translate('create_marker_map');
      case ContentType.expenses:
        return localizations.translate('add_expense');
      case ContentType.depthChart:
        return localizations.translate('view_depth_chart');
    }
  }

  IconData _getButtonIcon(bool canCreate) {
    if (customIcon != null) return customIcon!;

    if (!canCreate) return Icons.lock;

    switch (contentType) {
      case ContentType.fishingNotes:
        return Icons.note_add;
      case ContentType.markerMaps:
        return Icons.add_location;
      case ContentType.expenses:
        return Icons.add_shopping_cart;
      case ContentType.depthChart:
        return Icons.trending_up;
    }
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: contentType.name,
        ),
      ),
    );
  }
}

/// Специализированная кнопка FAB для создания контента
class PremiumFloatingActionButton extends StatelessWidget {
  final ContentType contentType;
  final VoidCallback onPressed;
  final String? heroTag;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PremiumFloatingActionButton({
    super.key,
    required this.contentType,
    required this.onPressed,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCreateButton(
      contentType: contentType,
      onCreatePressed: onPressed,
      isFloatingActionButton: true,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showUsageBadge: true,
    );
  }
}

/// Компактная кнопка создания для использования в списках
class CompactCreateButton extends StatelessWidget {
  final ContentType contentType;
  final VoidCallback onPressed;
  final EdgeInsets? margin;

  const CompactCreateButton({
    super.key,
    required this.contentType,
    required this.onPressed,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: PremiumCreateButton(
        contentType: contentType,
        onCreatePressed: onPressed,
        showUsageBadge: false,
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

/// Помощник для навигации с проверкой лимитов
class NavigationHelper {
  static Future<void> navigateWithLimitCheck({
    required BuildContext context,
    required ContentType contentType,
    required Widget destination,
    String? blockedFeature,
  }) async {
    final subscriptionService = SubscriptionService();

    // Проверка премиум функций
    if (blockedFeature != null) {
      if (!subscriptionService.hasPremiumAccess()) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaywallScreen(
              blockedFeature: blockedFeature,
            ),
          ),
        );
        return;
      }
    }

    // Проверка лимитов контента
    final canCreate = await subscriptionService.canCreateContent(contentType);

    if (!canCreate) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaywallScreen(
            contentType: contentType.name,
          ),
        ),
      );
      return;
    }

    // Навигация разрешена
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}

/// Виджет кнопки "+" с анимацией для индикации состояния лимитов
class AnimatedCreateButton extends StatefulWidget {
  final ContentType contentType;
  final VoidCallback onPressed;
  final double size;

  const AnimatedCreateButton({
    super.key,
    required this.contentType,
    required this.onPressed,
    this.size = 56,
  });

  @override
  State<AnimatedCreateButton> createState() => _AnimatedCreateButtonState();
}

class _AnimatedCreateButtonState extends State<AnimatedCreateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppConstants.primaryColor,
      end: Colors.orange,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();

        return FutureBuilder<bool>(
          future: subscriptionService.canCreateContent(widget.contentType),
          builder: (context, futureSnapshot) {
            final canCreate = futureSnapshot.data ?? false;

            if (!canCreate) {
              _animationController.repeat(reverse: true);
            } else {
              _animationController.stop();
              _animationController.reset();
            }

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: canCreate ? 1.0 : _scaleAnimation.value,
                  child: FloatingActionButton(
                    onPressed: canCreate
                        ? () => _handleCreatePress(context, subscriptionService)
                        : () => _showPaywall(context),
                    backgroundColor: canCreate
                        ? AppConstants.primaryColor
                        : _colorAnimation.value,
                    child: Icon(
                      canCreate ? Icons.add : Icons.lock,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ДОБАВЛЕНО: Обработчик нажатия с увеличением счетчика
  Future<void> _handleCreatePress(
      BuildContext context,
      SubscriptionService subscriptionService,
      ) async {
    // Увеличиваем счетчик использования (если не премиум)
    if (!subscriptionService.hasPremiumAccess()) {
      final success = await subscriptionService.incrementUsage(widget.contentType);
      if (!success) {
        _showPaywall(context);
        return;
      }
    }

    widget.onPressed();
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: widget.contentType.name,
        ),
      ),
    );
  }
}