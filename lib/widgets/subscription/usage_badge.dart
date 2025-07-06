// Путь: lib/widgets/subscription/usage_badge.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// Виджет для отображения текущего использования лимитов
class UsageBadge extends StatelessWidget {
  final ContentType contentType;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showIcon;
  final bool showPercentage;

  const UsageBadge({
    super.key,
    required this.contentType,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showIcon = true,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();
        final localizations = AppLocalizations.of(context);

        // Если премиум - показываем специальный бадж
        if (subscriptionService.hasPremiumAccess()) {
          return _buildPremiumBadge(localizations);
        }

        // ИСПРАВЛЕНО: Используем синхронную версию для получения данных
        final currentUsage = subscriptionService.getCurrentUsageSync(contentType);
        final limit = subscriptionService.getLimit(contentType);
        final usagePercent = limit > 0 ? (currentUsage / limit * 100).round() : 0;

        return _buildUsageBadge(
          localizations,
          currentUsage,
          limit,
          usagePercent,
        );
      },
    );
  }

  Widget _buildPremiumBadge(AppLocalizations localizations) {
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
          if (showIcon) ...[
            Icon(
              Icons.stars,
              color: Colors.white,
              size: fontSize! + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            localizations.translate('premium'),
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

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.fishingNotes:
        return Icons.note_alt;
      case ContentType.markerMaps:
        return Icons.map;
      case ContentType.expenses:
        return Icons.attach_money;
      case ContentType.depthChart:
        return Icons.trending_up;
    }
  }
}

/// Компактная версия баджа для отображения в списках
class CompactUsageBadge extends StatelessWidget {
  final ContentType contentType;
  final bool showOnlyWhenNearLimit;

  const CompactUsageBadge({
    super.key,
    required this.contentType,
    this.showOnlyWhenNearLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();

        // Если премиум - не показываем ничего
        if (subscriptionService.hasPremiumAccess()) {
          return const SizedBox();
        }

        // ИСПРАВЛЕНО: Используем синхронную версию для получения данных
        final currentUsage = subscriptionService.getCurrentUsageSync(contentType);
        final limit = subscriptionService.getLimit(contentType);
        final usagePercent = limit > 0 ? (currentUsage / limit * 100).round() : 0;

        // Если нужно показывать только при приближении к лимиту
        if (showOnlyWhenNearLimit && usagePercent < 80) {
          return const SizedBox();
        }

        return UsageBadge(
          contentType: contentType,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          showIcon: false,
        );
      },
    );
  }
}

/// Виджет для отображения прогресс-бара использования
class UsageProgressBar extends StatelessWidget {
  final ContentType contentType;
  final double height;
  final bool showText;

  const UsageProgressBar({
    super.key,
    required this.contentType,
    this.height = 6,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: SubscriptionService().subscriptionStream,
      builder: (context, snapshot) {
        final subscriptionService = SubscriptionService();
        final localizations = AppLocalizations.of(context);

        // Если премиум - показываем специальный индикатор
        if (subscriptionService.hasPremiumAccess()) {
          return _buildPremiumIndicator(localizations);
        }

        // ИСПРАВЛЕНО: Используем синхронную версию для получения данных
        final currentUsage = subscriptionService.getCurrentUsageSync(contentType);
        final limit = subscriptionService.getLimit(contentType);
        final progress = limit > 0 ? currentUsage / limit : 0.0;

        Color progressColor;
        if (progress >= 1.0) {
          progressColor = Colors.red;
        } else if (progress >= 0.8) {
          progressColor = Colors.orange;
        } else if (progress >= 0.6) {
          progressColor = Colors.amber;
        } else {
          progressColor = AppConstants.primaryColor;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showText) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getContentTypeName(contentType, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$currentUsage/$limit',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: height,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumIndicator(AppLocalizations localizations) {
    if (!showText) {
      return const SizedBox();
    }

    return Row(
      children: [
        const Icon(
          Icons.stars,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_getContentTypeName(contentType, localizations)} - ${localizations.translate('unlimited')}',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getContentTypeName(ContentType type, AppLocalizations localizations) {
    switch (type) {
      case ContentType.fishingNotes:
        return localizations.translate('fishing_notes');
      case ContentType.markerMaps:
        return localizations.translate('marker_maps');
      case ContentType.expenses:
        return localizations.translate('expenses');
      case ContentType.depthChart:
        return localizations.translate('depth_chart');
    }
  }
}