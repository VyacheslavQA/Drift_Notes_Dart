// Путь: lib/widgets/subscription/premium_create_button.dart

import 'package:flutter/material.dart';
import '../../models/subscription_model.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/firebase/firebase_service.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';
import '../../constants/app_constants.dart';
import 'usage_badge.dart';

/// Кнопка создания контента с автоматической проверкой лимитов
class PremiumCreateButton extends StatefulWidget {
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
  State<PremiumCreateButton> createState() => _PremiumCreateButtonState();
}

class _PremiumCreateButtonState extends State<PremiumCreateButton> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _canCreate = false;
  bool _isLoading = true;
  int _currentUsage = 0;
  int _limit = 0;

  @override
  void initState() {
    super.initState();
    _checkLimits();
  }

  /// 🔥 ИСПРАВЛЕНО: Проверка лимитов через новую Firebase систему
  Future<void> _checkLimits() async {
    try {
      // 1. Проверяем премиум доступ
      if (_subscriptionService.hasPremiumAccess()) {
        if (mounted) {
          setState(() {
            _canCreate = true;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Для графика глубин - только премиум
      if (widget.contentType == ContentType.depthChart) {
        if (mounted) {
          setState(() {
            _canCreate = false;
            _isLoading = false;
          });
        }
        return;
      }

      // 3. 🔥 ИСПРАВЛЕНО: Проверяем лимиты через новую Firebase систему
      final limitCheck = await _firebaseService.canCreateItem(_getFirebaseKey(widget.contentType));

      final canCreate = limitCheck['canProceed'] ?? false;
      final currentUsage = limitCheck['currentCount'] ?? 0;
      final maxLimit = limitCheck['maxLimit'] ?? 0;

      if (mounted) {
        setState(() {
          _canCreate = canCreate;
          _currentUsage = currentUsage;
          _limit = maxLimit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ PremiumCreateButton: Ошибка проверки лимитов: $e');

      if (mounted) {
        setState(() {
          _canCreate = false;
          _isLoading = false;
        });
      }
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

        if (_isLoading) {
          return _buildLoadingButton(context, localizations);
        }

        if (widget.isFloatingActionButton) {
          return _buildFloatingActionButton(
            context,
            localizations,
          );
        }

        return _buildRegularButton(
          context,
          localizations,
        );
      },
    );
  }

  Widget _buildLoadingButton(BuildContext context, AppLocalizations localizations) {
    if (widget.isFloatingActionButton) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        minimumSize: const Size(double.infinity, 56),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }

  Widget _buildFloatingActionButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showUsageBadge && !_subscriptionService.hasPremiumAccess()) ...[
          CompactUsageBadge(
            contentType: widget.contentType,
            showOnlyWhenNearLimit: true,
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _canCreate
              ? () => _handleCreatePress(context)
              : () => _showPaywall(context),
          backgroundColor: _canCreate
              ? (widget.backgroundColor ?? AppConstants.primaryColor)
              : Colors.grey.withOpacity(0.7),
          foregroundColor: _canCreate
              ? (widget.foregroundColor ?? Colors.white)
              : Colors.white70,
          child: Stack(
            children: [
              Icon(
                _canCreate
                    ? (widget.customIcon ?? Icons.add)
                    : Icons.lock,
                size: 28,
              ),
              if (!_canCreate)
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
      AppLocalizations localizations,
      ) {
    final buttonText = _getButtonText(localizations, _canCreate);
    final buttonIcon = _getButtonIcon(_canCreate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _canCreate
              ? () => _handleCreatePress(context)
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
              if (widget.showUsageBadge)
                UsageBadge(
                  contentType: widget.contentType,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _canCreate
                ? (widget.backgroundColor ?? AppConstants.primaryColor)
                : Colors.grey.withOpacity(0.5),
            foregroundColor: _canCreate
                ? (widget.foregroundColor ?? Colors.white)
                : Colors.white70,
            padding: widget.padding ?? const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
              side: !_canCreate
                  ? const BorderSide(color: Colors.orange, width: 2)
                  : BorderSide.none,
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        if (!_canCreate) ...[
          const SizedBox(height: 8),
          _buildLimitWarning(context, localizations),
        ],
      ],
    );
  }

  Widget _buildLimitWarning(
      BuildContext context,
      AppLocalizations localizations,
      ) {
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
              '${localizations.translate('limit_reached_description') ?? 'Достигнут лимит'} ($_currentUsage/$_limit)',
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
              localizations.translate('upgrade_now') ?? 'Обновить',
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

  /// 🔥 ИСПРАВЛЕНО: Обработчик нажатия
  Future<void> _handleCreatePress(BuildContext context) async {
    // Просто вызываем оригинальный колбэк
    // Увеличение счетчика происходит в самих экранах создания
    widget.onCreatePressed();
  }

  String _getButtonText(AppLocalizations localizations, bool canCreate) {
    if (widget.customText != null) return widget.customText!;

    if (!canCreate) {
      return localizations.translate('limit_reached_short') ?? 'Лимит достигнут';
    }

    switch (widget.contentType) {
      case ContentType.fishingNotes:
        return localizations.translate('create_fishing_note') ?? 'Создать заметку';
      case ContentType.markerMaps:
        return localizations.translate('create_marker_map') ?? 'Создать карту';
      case ContentType.expenses:
        return localizations.translate('add_expense') ?? 'Добавить расход';
      case ContentType.depthChart:
        return localizations.translate('view_depth_chart') ?? 'График глубин';
    }
  }

  IconData _getButtonIcon(bool canCreate) {
    if (widget.customIcon != null) return widget.customIcon!;

    if (!canCreate) return Icons.lock;

    switch (widget.contentType) {
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
          contentType: widget.contentType.name,
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
    final firebaseService = FirebaseService();

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

    // 🔥 ИСПРАВЛЕНО: Проверка лимитов через новую Firebase систему
    try {
      String firebaseKey;
      switch (contentType) {
        case ContentType.fishingNotes:
          firebaseKey = 'notesCount';
          break;
        case ContentType.markerMaps:
          firebaseKey = 'markerMapsCount';
          break;
        case ContentType.expenses:
          firebaseKey = 'expensesCount';
          break;
        case ContentType.depthChart:
          firebaseKey = 'depthChartCount';
          break;
      }

      final limitCheck = await firebaseService.canCreateItem(firebaseKey);
      final canCreate = limitCheck['canProceed'] ?? false;

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
    } catch (e) {
      // При ошибке показываем paywall
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaywallScreen(
            contentType: contentType.name,
          ),
        ),
      );
    }
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

  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _canCreate = false;
  bool _isLoading = true;

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

    _checkLimits();
  }

  Future<void> _checkLimits() async {
    try {
      if (_subscriptionService.hasPremiumAccess()) {
        setState(() {
          _canCreate = true;
          _isLoading = false;
        });
        return;
      }

      if (widget.contentType == ContentType.depthChart) {
        setState(() {
          _canCreate = false;
          _isLoading = false;
        });
        return;
      }

      String firebaseKey;
      switch (widget.contentType) {
        case ContentType.fishingNotes:
          firebaseKey = 'notesCount';
          break;
        case ContentType.markerMaps:
          firebaseKey = 'markerMapsCount';
          break;
        case ContentType.expenses:
          firebaseKey = 'expensesCount';
          break;
        case ContentType.depthChart:
          firebaseKey = 'depthChartCount';
          break;
      }

      final limitCheck = await _firebaseService.canCreateItem(firebaseKey);
      final canCreate = limitCheck['canProceed'] ?? false;

      if (mounted) {
        setState(() {
          _canCreate = canCreate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canCreate = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (!_canCreate) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _canCreate ? 1.0 : _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _canCreate
                ? widget.onPressed
                : () => _showPaywall(context),
            backgroundColor: _canCreate
                ? AppConstants.primaryColor
                : _colorAnimation.value,
            child: Icon(
              _canCreate ? Icons.add : Icons.lock,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
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