// Путь: lib/widgets/subscription/usage_badge.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

/// Виджет для отображения текущего использования лимитов
class UsageBadge extends StatefulWidget {
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

  /// 🔥 ИСПРАВЛЕНО: Загрузка данных через новую Firebase систему
  Future<void> _loadUsageData() async {
    try {
      debugPrint('🔄 UsageBadge: Загрузка данных для ${widget.contentType}');

      // 1. Получаем лимит (синхронно)
      final limit = _subscriptionService.getLimit(widget.contentType);

      // 2. 🔥 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Получаем текущее использование через новую Firebase систему
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

  /// 🔥 НОВЫЙ МЕТОД: Получение текущего использования через Firebase
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

  /// 🔥 НОВЫЙ МЕТОД: Преобразование ContentType в ключ Firebase
  String _getFirebaseKey(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.expenses:
        return 'expensesCount';
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

        // 🔥 ИСПРАВЛЕНО: Используем данные из Firebase
        final usagePercent = _limit > 0 ? (_currentUsage / _limit * 100).round() : 0;

        return _buildUsageBadge(
          localizations,
          _currentUsage,
          _limit,
          usagePercent,
        );
      },
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              _getContentTypeIcon(widget.contentType),
              color: Colors.grey,
              size: widget.fontSize! + 2,
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
    return Container(
      padding: widget.padding,
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
          if (widget.showIcon) ...[
            Icon(
              Icons.stars,
              color: Colors.white,
              size: widget.fontSize! + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            localizations.translate('premium') ?? 'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.fontSize,
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
class CompactUsageBadge extends StatefulWidget {
  final ContentType contentType;
  final bool showOnlyWhenNearLimit;

  const CompactUsageBadge({
    super.key,
    required this.contentType,
    this.showOnlyWhenNearLimit = false,
  });

  @override
  State<CompactUsageBadge> createState() => _CompactUsageBadgeState();
}

class _CompactUsageBadgeState extends State<CompactUsageBadge> {
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

  Future<void> _loadUsageData() async {
    try {
      final limit = _subscriptionService.getLimit(widget.contentType);
      final currentUsage = await _getCurrentUsageFromFirebase();

      if (mounted) {
        setState(() {
          _currentUsage = currentUsage;
          _limit = limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUsage = 0;
          _limit = _subscriptionService.getLimit(widget.contentType);
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _getCurrentUsageFromFirebase() async {
    try {
      final stats = await _firebaseService.getUsageStatistics();
      final String firebaseKey = _getFirebaseKey(widget.contentType);
      return stats[firebaseKey] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _getFirebaseKey(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.expenses:
        return 'expensesCount';
      case ContentType.depthChart:
        return 'depthChartCount';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel>(
      stream: _subscriptionService.subscriptionStream,
      builder: (context, snapshot) {
        // Если премиум - не показываем ничего
        if (_subscriptionService.hasPremiumAccess()) {
          return const SizedBox();
        }

        if (_isLoading) {
          return const SizedBox();
        }

        final usagePercent = _limit > 0 ? (_currentUsage / _limit * 100).round() : 0;

        // Если нужно показывать только при приближении к лимиту
        if (widget.showOnlyWhenNearLimit && usagePercent < 80) {
          return const SizedBox();
        }

        return UsageBadge(
          contentType: widget.contentType,
          fontSize: 10,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          showIcon: false,
        );
      },
    );
  }
}

/// Виджет для отображения прогресс-бара использования
class UsageProgressBar extends StatefulWidget {
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
  State<UsageProgressBar> createState() => _UsageProgressBarState();
}

class _UsageProgressBarState extends State<UsageProgressBar> {
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

  Future<void> _loadUsageData() async {
    try {
      final limit = _subscriptionService.getLimit(widget.contentType);
      final currentUsage = await _getCurrentUsageFromFirebase();

      if (mounted) {
        setState(() {
          _currentUsage = currentUsage;
          _limit = limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUsage = 0;
          _limit = _subscriptionService.getLimit(widget.contentType);
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _getCurrentUsageFromFirebase() async {
    try {
      final stats = await _firebaseService.getUsageStatistics();
      final String firebaseKey = _getFirebaseKey(widget.contentType);
      return stats[firebaseKey] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _getFirebaseKey(ContentType contentType) {
    switch (contentType) {
      case ContentType.fishingNotes:
        return 'notesCount';
      case ContentType.markerMaps:
        return 'markerMapsCount';
      case ContentType.expenses:
        return 'expensesCount';
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

        // Если премиум - показываем специальный индикатор
        if (_subscriptionService.hasPremiumAccess()) {
          return _buildPremiumIndicator(localizations);
        }

        if (_isLoading) {
          return const SizedBox(
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final progress = _limit > 0 ? _currentUsage / _limit : 0.0;

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
            if (widget.showText) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getContentTypeName(widget.contentType, localizations),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$_currentUsage/$_limit',
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
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: widget.height,
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
    if (!widget.showText) {
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
            '${_getContentTypeName(widget.contentType, localizations)} - ${localizations.translate('unlimited') ?? 'Безлимитно'}',
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
        return localizations.translate('fishing_notes') ?? 'Заметки рыбалки';
      case ContentType.markerMaps:
        return localizations.translate('marker_maps') ?? 'Маркерные карты';
      case ContentType.expenses:
        return localizations.translate('expenses') ?? 'Расходы';
      case ContentType.depthChart:
        return localizations.translate('depth_chart') ?? 'Графики глубин';
    }
  }
}