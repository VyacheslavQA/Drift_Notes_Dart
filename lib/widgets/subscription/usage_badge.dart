// Путь: lib/widgets/subscription/usage_badge.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// ✅ УПРОЩЕННЫЙ универсальный виджет для отображения текущего использования лимитов
class UsageBadge extends StatefulWidget {
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
  State<UsageBadge> createState() => _UsageBadgeState();
}

class _UsageBadgeState extends State<UsageBadge> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  int _currentUsage = 0;
  int _limit = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  /// ✅ УПРОЩЕННЫЙ: Единый метод загрузки данных через новую Firebase систему
  Future<void> _loadUsageData() async {
    try {
      debugPrint('🔄 UsageBadge: Загрузка данных для ${widget.contentType}');

      // 1. Получаем лимит (синхронно)
      final limit = _subscriptionService.getLimit(widget.contentType);

      // 2. ✅ ИСПРАВЛЕНО: Получаем текущее использование через новую Firebase систему
      final currentUsage = await _getCurrentUsageFromFirebase();

      debugPrint('📊 UsageBadge: ${widget.contentType} = $currentUsage/$limit');

      if (mounted) {
        setState(() {
          _currentUsage = currentUsage;
          _limit = limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ UsageBadge: Ошибка загрузки данных: $e');

      if (mounted) {
        setState(() {
          _currentUsage = 0;
          _limit = _subscriptionService.getLimit(widget.contentType);
          _isLoading = false;
        });
      }
    }
  }

  /// ✅ УПРОЩЕННЫЙ: Единый метод получения текущего использования
  Future<int> _getCurrentUsageFromFirebase() async {
    try {
      // Получаем статистику напрямую из Firebase
      final stats = await _firebaseService.getUsageStatistics();

      // Преобразуем ContentType в ключ Firebase
      final String firebaseKey = _getFirebaseKey(widget.contentType);

      final currentUsage = stats[firebaseKey] ?? 0;
      debugPrint('🔥 Firebase stats[$firebaseKey] = $currentUsage');

      return currentUsage;
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики из Firebase: $e');
      return 0;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Преобразование ContentType в ключ Firebase
  String _getFirebaseKey(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.budgetNotes: // ✅ ИСПРАВЛЕНО: было expenses
        return 'budgetNotesCount';
      case ContentType.depthChart:
        return 'depthChartCount';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: _subscriptionService.subscriptionStream,
      builder: (context, snapshot) {
        final localizations = AppLocalizations.of(context);

        // Если премиум - показываем специальный бадж
        if (_subscriptionService.hasPremiumAccess()) {
          return _buildPremiumBadge(localizations);
        }

        // Если загружается - показываем индикатор
        if (_isLoading) {
          return _buildLoadingBadge();
        }

        // Проверяем нужно ли показывать при приближении к лимиту
        final usagePercent = _limit > 0 ? (_currentUsage / _limit * 100).round() : 0;
        if (widget.showOnlyWhenNearLimit && usagePercent < 80) {
          return const SizedBox();
        }

        // Проверяем вариант отображения
        switch (widget.variant) {
          case BadgeVariant.always:
            return _buildUsageBadge(localizations, _currentUsage, _limit, usagePercent);
          case BadgeVariant.compact:
            return _buildCompactBadge(localizations, _currentUsage, _limit, usagePercent);
          case BadgeVariant.hidden:
            return const SizedBox();
        }
      },
    );
  }

  Widget _buildLoadingBadge() {
    // Для скрытого варианта не показываем загрузку
    if (widget.variant == BadgeVariant.hidden) {
      return const SizedBox();
    }

    final isCompact = widget.variant == BadgeVariant.compact;
    final iconSize = isCompact ? 10.0 : widget.fontSize! + 2;

    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon && !isCompact) ...[
            Icon(
              _getContentTypeIcon(widget.contentType),
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
    if (widget.variant == BadgeVariant.hidden) {
      return const SizedBox();
    }

    final isCompact = widget.variant == BadgeVariant.compact;
    final fontSize = isCompact ? 10.0 : widget.fontSize;
    final iconSize = isCompact ? 12.0 : fontSize! + 2;
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : widget.padding;

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
          if (widget.showIcon && !isCompact) ...[
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
      padding: widget.padding,
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
          if (widget.showIcon) ...[
            Icon(
              _getContentTypeIcon(widget.contentType),
              color: textColor,
              size: widget.fontSize! + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            widget.showPercentage
                ? '$usagePercent%'
                : '$currentUsage/$limit',
            style: TextStyle(
              color: textColor,
              fontSize: widget.fontSize,
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
        widget.showPercentage
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

  /// ✅ ИСПРАВЛЕНО: Иконки для типов контента
  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.fishingNotes:
        return Icons.note_alt;
      case ContentType.markerMaps:
        return Icons.map;
      case ContentType.budgetNotes: // ✅ ИСПРАВЛЕНО: было expenses
        return Icons.account_balance_wallet;
      case ContentType.depthChart:
        return Icons.trending_up;
    }
  }
}

/// ✅ УПРОЩЕННЫЕ варианты значков (перенесены из premium_create_button.dart)
enum BadgeVariant {
  always,     // всегда показывать на основных экранах
  compact,    // компактный для кнопок
  hidden,     // скрыть если не нужен
}