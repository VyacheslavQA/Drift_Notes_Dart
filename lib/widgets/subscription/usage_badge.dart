// Путь: lib/widgets/subscription/usage_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../constants/subscription_constants.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// ✅ ИСПРАВЛЕННЫЙ универсальный виджет для отображения текущего использования лимитов
/// Теперь работает через SubscriptionProvider
class UsageBadge extends StatelessWidget {
  final ContentType contentType;
  final BadgeVariant variant;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showIcon;
  final bool showPercentage;
  final bool showOnlyWhenNearLimit;

  const UsageBadge({
    super.key,
    required this.contentType,
    this.variant = BadgeVariant.always,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showIcon = true,
    this.showPercentage = false,
    this.showOnlyWhenNearLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Если премиум - показываем специальный бадж
        if (subscriptionProvider.hasPremiumAccess) {
          return _buildPremiumBadge(localizations);
        }

        // Если загружается - показываем индикатор
        if (subscriptionProvider.isLoading) {
          return _buildLoadingBadge();
        }

        // Получаем данные из Provider
        final currentUsage = subscriptionProvider.getUsage(contentType) ?? 0;
        final limit = subscriptionProvider.getLimit(contentType);

        // Проверяем нужно ли показывать при приближении к лимиту
        final usagePercent = limit > 0 ? (currentUsage / limit * 100).round() : 0;
        if (showOnlyWhenNearLimit && usagePercent < 80) {
          return const SizedBox();
        }

        // Проверяем вариант отображения
        switch (variant) {
          case BadgeVariant.always:
            return _buildUsageBadge(localizations, currentUsage, limit, usagePercent);
          case BadgeVariant.compact:
            return _buildCompactBadge(localizations, currentUsage, limit, usagePercent);
          case BadgeVariant.hidden:
            return const SizedBox();
        }
      },
    );
  }

  Widget _buildLoadingBadge() {
    // Для скрытого варианта не показываем загрузку
    if (variant == BadgeVariant.hidden) {
      return const SizedBox();
    }

    final isCompact = variant == BadgeVariant.compact;
    final iconSize = isCompact ? 10.0 : fontSize! + 2;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && !isCompact) ...[
            Icon(
              _getContentTypeIcon(contentType),
              color: Colors.grey,
              size: iconSize,
            ),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadge(AppLocalizations localizations) {
    // Для скрытого варианта не показываем премиум
    if (variant == BadgeVariant.hidden) {
      return const SizedBox();
    }

    final isCompact = variant == BadgeVariant.compact;
    final fontSize = isCompact ? 10.0 : this.fontSize;
    final iconSize = isCompact ? 12.0 : fontSize! + 2;
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : this.padding;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && !isCompact) ...[
            Icon(
              Icons.stars,
              color: Colors.white,
              size: iconSize,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isCompact ? '∞' : (localizations.translate('premium') ?? 'Premium'),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBadge(
      AppLocalizations localizations,
      int currentUsage,
      int limit,
      int usagePercent,
      ) {
    Color badgeColor;
    Color textColor;

    if (usagePercent >= 100) {
      // Лимит достигнут
      badgeColor = Colors.red;
      textColor = Colors.white;
    } else if (usagePercent >= 80) {
      // Близко к лимиту
      badgeColor = Colors.orange;
      textColor = Colors.white;
    } else if (usagePercent >= 60) {
      // Средний уровень использования
      badgeColor = Colors.amber;
      textColor = Colors.black87;
    } else {
      // Низкий уровень использования
      badgeColor = AppConstants.primaryColor;
      textColor = Colors.white;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getContentTypeIcon(contentType),
              color: textColor,
              size: fontSize! + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            showPercentage
                ? '$usagePercent%'
                : '$currentUsage/$limit',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge(
      AppLocalizations localizations,
      int currentUsage,
      int limit,
      int usagePercent,
      ) {
    Color badgeColor;
    Color textColor;

    if (usagePercent >= 100) {
      badgeColor = Colors.red;
      textColor = Colors.white;
    } else if (usagePercent >= 80) {
      badgeColor = Colors.orange;
      textColor = Colors.white;
    } else if (usagePercent >= 60) {
      badgeColor = Colors.amber;
      textColor = Colors.black87;
    } else {
      badgeColor = AppConstants.primaryColor;
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        showPercentage
            ? '$usagePercent%'
            : '$currentUsage/$limit',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🚀 ИСПРАВЛЕНО: Добавлен case для markerMapSharing
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.fishingNotes:
        return Icons.note_alt;
      case ContentType.markerMaps:
        return Icons.map;
      case ContentType.budgetNotes:
        return Icons.account_balance_wallet;
      case ContentType.depthChart:
        return Icons.trending_up;
      case ContentType.markerMapSharing: // 🚀 НОВОЕ
        return Icons.share;
    }
  }
}

/// ✅ УПРОЩЕННЫЕ варианты значков
enum BadgeVariant {
  always,     // всегда показывать на основных экранах
  compact,    // компактный для кнопок
  hidden,     // скрыть если не нужен
}