// Путь: lib/screens/subscription/paywall_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/subscription_constants.dart';
import '../../providers/subscription_provider.dart';
import '../../localization/app_localizations.dart';

class PaywallScreen extends StatefulWidget {
  final String? contentType; // Тип контента, который пытался создать пользователь
  final String? blockedFeature; // Заблокированная функция

  const PaywallScreen({
    super.key,
    this.contentType,
    this.blockedFeature,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedPlan = SubscriptionConstants.yearlyPremiumId;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProducts();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  /// 🆕 ОБНОВЛЕНО: Загрузка продуктов с обновлением реальных цен из Google Play
  void _loadProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);

      // Загружаем продукты если их нет
      if (provider.availableProducts.isEmpty) {
        await provider.loadAvailableProducts();
      }

      // 🆕 НОВОЕ: Принудительно обновляем цены из Google Play
      try {
        await provider.refreshProductPrices();
      } catch (e) {
        // Тихо обрабатываем ошибки - будут использованы фоллбэк цены
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppConstants.paddingMedium),
                      _buildHeroSection(context),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildFeaturesList(context),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildPlanSelector(context, provider),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildActionButtons(context, provider),
                      const SizedBox(height: AppConstants.paddingMedium),
                      _buildFooterText(context),
                      const SizedBox(height: AppConstants.paddingLarge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppConstants.textColor,
              size: 28,
            ),
          ),
          const Spacer(),
          Text(
            _getHeaderTitle(context),
            style: AppConstants.titleStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 56), // Для баланса с кнопкой закрытия
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diamond_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _getTitle(context),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _getSubtitle(context),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = _getFeatures(context);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: features.asMap().entries.map((entry) {
          return _buildFeatureItem(
            icon: entry.value['icon'] as IconData,
            title: entry.value['title'] as String,
            subtitle: entry.value['subtitle'] as String,
            isLast: entry.key == features.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppConstants.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppConstants.bodyStyle.copyWith(
                    color: AppConstants.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(BuildContext context, SubscriptionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedText(context, 'choose_plan'),
          style: AppConstants.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        _buildPlanOption(
          context,
          provider,
          SubscriptionConstants.yearlyPremiumId,
          true, // Рекомендуемый
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        _buildPlanOption(
          context,
          provider,
          SubscriptionConstants.monthlyPremiumId,
          false,
        ),
      ],
    );
  }

  Widget _buildPlanOption(
      BuildContext context,
      SubscriptionProvider provider,
      String planId,
      bool isRecommended,
      ) {
    final isSelected = _selectedPlan == planId;
    final product = provider.getProductById(planId);

    // 🆕 УЛУЧШЕНО: Приоритет реальным ценам из Google Play, затем умный фоллбэк
    String price;
    if (product?.price != null && product!.price.isNotEmpty) {
      // Используем реальную цену из Google Play
      price = product.price;
    } else {
      // Умный фоллбэк к региональным ценам
      price = _getSmartFallbackPrice(planId);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planId;
        });
      },
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : AppConstants.cardColor,
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : AppConstants.dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: isSelected ? AppConstants.cardShadow : null,
        ),
        child: Stack(
          children: [
            // Бейдж "Рекомендуем"
            if (isRecommended)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 120,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getLocalizedText(context, 'recommended'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Основной контент
            Padding(
              padding: EdgeInsets.only(
                left: AppConstants.paddingMedium,
                right: AppConstants.paddingMedium,
                bottom: AppConstants.paddingMedium,
                top: isRecommended ? AppConstants.paddingLarge : AppConstants.paddingMedium,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: planId,
                    groupValue: _selectedPlan,
                    onChanged: (value) {
                      setState(() {
                        _selectedPlan = value!;
                      });
                    },
                    activeColor: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _getPlanTitle(context, planId),
                                style: AppConstants.subtitleStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isRecommended && provider.getYearlyDiscount() > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${provider.getYearlyDiscount().round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPlanSubtitle(context, planId, price),
                          style: AppConstants.bodyStyle.copyWith(
                            color: AppConstants.secondaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  // Цена
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 70,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            price,
                            style: AppConstants.titleStyle.copyWith(
                              fontSize: 18,
                              color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            planId == SubscriptionConstants.monthlyPremiumId
                                ? _getLocalizedText(context, 'per_month')
                                : _getLocalizedText(context, 'per_year'),
                            style: AppConstants.captionStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SubscriptionProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: provider.isPurchasing ? null : () => _purchaseSubscription(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              elevation: 4,
            ),
            child: provider.isPurchasing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              _getLocalizedText(context, 'continue'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        TextButton(
          onPressed: provider.isLoading ? null : () => _restorePurchases(provider),
          child: Text(
            _getLocalizedText(context, 'restore_purchases'),
            style: const TextStyle(
              color: AppConstants.secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterText(BuildContext context) {
    return Text(
      _getLocalizedText(context, 'paywall_footer'),
      style: AppConstants.captionStyle.copyWith(
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 🆕 УЛУЧШЕНО: Умный фоллбэк цены с учетом региона пользователя
  String _getSmartFallbackPrice(String planId) {
    try {
      // Получаем локаль пользователя
      final locale = Localizations.localeOf(context);

      // Определяем регион по коду страны или языку
      if (locale.countryCode == 'RU' || locale.languageCode == 'ru') {
        // Российские цены
        if (planId == SubscriptionConstants.monthlyPremiumId) {
          return '₽299';
        } else if (planId == SubscriptionConstants.yearlyPremiumId) {
          return '₽2490';
        }
      } else if (locale.countryCode == 'KZ') {
        // Казахстанские цены
        if (planId == SubscriptionConstants.monthlyPremiumId) {
          return '₸1490';
        } else if (planId == SubscriptionConstants.yearlyPremiumId) {
          return '₸11990';
        }
      } else if (locale.countryCode == 'BY') {
        // Беларусь - используем российские цены
        if (planId == SubscriptionConstants.monthlyPremiumId) {
          return '₽299';
        } else if (planId == SubscriptionConstants.yearlyPremiumId) {
          return '₽2490';
        }
      }

      // Международные фоллбэк цены (USD)
      if (planId == SubscriptionConstants.monthlyPremiumId) {
        return '\$4.99';
      } else if (planId == SubscriptionConstants.yearlyPremiumId) {
        return '\$39.99';
      }
    } catch (e) {
      // При ошибке возвращаем базовые USD цены
    }

    return '\$4.99';
  }

  /// 🆕 УСТАРЕЛО: Простой фоллбэк (оставлен для совместимости)
  String _getFallbackPrice(String planId) {
    if (planId == SubscriptionConstants.monthlyPremiumId) {
      return '\$4.99';
    } else if (planId == SubscriptionConstants.yearlyPremiumId) {
      return '\$39.99';
    }
    return '\$4.99';
  }

  Future<void> _purchaseSubscription(SubscriptionProvider provider) async {
    final success = await provider.purchaseSubscription(_selectedPlan);

    if (success && mounted) {
      // Покупка инициирована успешно
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedText(context, 'purchase_initiated')),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    } else if (provider.lastError != null && mounted) {
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.lastError!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restorePurchases(SubscriptionProvider provider) async {
    await provider.restorePurchases();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedText(context, 'purchases_restored')),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    }
  }

  String _getHeaderTitle(BuildContext context) {
    if (widget.contentType != null) {
      return _getLocalizedText(context, 'upgrade_required');
    }
    return _getLocalizedText(context, 'premium_subscription');
  }

  String _getTitle(BuildContext context) {
    if (widget.contentType != null) {
      return _getLocalizedText(context, 'unlock_premium_features');
    }
    return _getLocalizedText(context, 'go_premium');
  }

  String _getSubtitle(BuildContext context) {
    if (widget.contentType != null) {
      return _getLocalizedText(context, 'subscription_required_message');
    }
    return _getLocalizedText(context, 'premium_benefits_message');
  }

  List<Map<String, dynamic>> _getFeatures(BuildContext context) {
    return [
      {
        'icon': Icons.note_add,
        'title': _getLocalizedText(context, 'unlimited_notes'),
        'subtitle': _getLocalizedText(context, 'unlimited_notes_desc'),
      },
      {
        'icon': Icons.map,
        'title': _getLocalizedText(context, 'unlimited_maps'),
        'subtitle': _getLocalizedText(context, 'unlimited_maps_desc'),
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': _getLocalizedText(context, 'unlimited_expenses'),
        'subtitle': _getLocalizedText(context, 'unlimited_expenses_desc'),
      },
      {
        'icon': Icons.show_chart,
        'title': _getLocalizedText(context, 'depth_charts'),
        'subtitle': _getLocalizedText(context, 'depth_charts_desc'),
      },
    ];
  }

  String _getPlanTitle(BuildContext context, String planId) {
    return planId == SubscriptionConstants.monthlyPremiumId
        ? _getLocalizedText(context, 'monthly_plan')
        : _getLocalizedText(context, 'yearly_plan');
  }

  String _getPlanSubtitle(BuildContext context, String planId, String price) {
    if (planId == SubscriptionConstants.monthlyPremiumId) {
      return _getLocalizedText(context, 'monthly_plan_desc');
    } else {
      return _getLocalizedText(context, 'yearly_plan_desc');
    }
  }

  String _getLocalizedText(BuildContext context, String key) {
    try {
      final localizations = AppLocalizations.of(context);
      return localizations.translate(key);
    } catch (e) {
      // Fallback на английский
      return _getFallbackText(key);
    }
  }

  String _getFallbackText(String key) {
    switch (key) {
      case 'choose_plan':
        return 'Choose Your Plan';
      case 'recommended':
        return 'Recommended';
      case 'continue':
        return 'Continue';
      case 'restore_purchases':
        return 'Restore Purchases';
      case 'per_month':
        return '/month';
      case 'per_year':
        return '/year';
      case 'upgrade_required':
        return 'Upgrade Required';
      case 'premium_subscription':
        return 'Premium Subscription';
      case 'unlock_premium_features':
        return 'Unlock Premium Features';
      case 'go_premium':
        return 'Go Premium';
      case 'subscription_required_message':
        return 'This feature requires a premium subscription. Upgrade now to continue.';
      case 'premium_benefits_message':
        return 'Get unlimited access to all features and enhance your fishing experience.';
      case 'unlimited_notes':
        return 'Unlimited Notes';
      case 'unlimited_notes_desc':
        return 'Create unlimited fishing notes';
      case 'unlimited_maps':
        return 'Unlimited Maps';
      case 'unlimited_maps_desc':
        return 'Create unlimited marker maps';
      case 'unlimited_expenses':
        return 'Unlimited Expenses';
      case 'unlimited_expenses_desc':
        return 'Track unlimited fishing expenses';
      case 'depth_charts':
        return 'Depth Charts';
      case 'depth_charts_desc':
        return 'Access advanced depth charts';
      case 'monthly_plan':
        return 'Monthly Premium';
      case 'yearly_plan':
        return 'Yearly Premium';
      case 'monthly_plan_desc':
        return 'Full access, billed monthly';
      case 'yearly_plan_desc':
        return 'Best value, billed annually';
      case 'paywall_footer':
        return 'Subscription will be charged to your account. Manage subscription in Google Play Store.';
      case 'purchase_initiated':
        return 'Purchase initiated successfully';
      case 'purchases_restored':
        return 'Purchases restored successfully';
      default:
        return key;
    }
  }
}