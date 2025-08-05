// Путь: lib/screens/subscription/subscription_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/subscription_constants.dart';
import '../../localization/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../models/subscription_model.dart';

/// Экран управления активной подпиской пользователя
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscriptionData();
    });
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.refreshData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Открытие страницы управления подписками в Google Play
  Future<void> _openGooglePlaySubscriptions() async {
    final localizations = AppLocalizations.of(context);

    try {
      const url = 'https://play.google.com/store/account/subscriptions';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(localizations.translate('failed_to_open_google_play'));
      }
    } catch (e) {
      _showErrorSnackBar(localizations.translate('link_open_error'));
    }
  }

  /// Показ диалога с инструкцией по отмене
  void _showCancelInstructionDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('cancel_subscription_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.translate('cancel_step_1')),
            const SizedBox(height: 8),
            Text(localizations.translate('cancel_step_2')),
            const SizedBox(height: 8),
            Text(localizations.translate('cancel_step_3')),
            const SizedBox(height: 8),
            Text(localizations.translate('cancel_step_4')),
            const SizedBox(height: 8),
            Text(localizations.translate('cancel_step_5')),
            const SizedBox(height: 16),
            Text(
              localizations.translate('cancel_note'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('understood')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openGooglePlaySubscriptions();
            },
            child: Text(localizations.translate('open_google_play')),
          ),
        ],
      ),
    );
  }

  /// 🆕 НОВОЕ: Показ диалога связи с поддержкой с активной почтой
  void _showSupportDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            localizations.translate('support'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🎨 ЦЕНТРИРОВАННЫЙ текст поддержки
            Center(
              child: Text(
                localizations.translate('support_contacts'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            // 🎨 ЦЕНТРИРОВАННАЯ кнопка email
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openEmailClient(),
                icon: const Icon(Icons.email, size: 20),
                label: Text(
                  localizations.translate('write_email'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // 🎨 ЦЕНТРИРОВАННАЯ кнопка "Понятно"
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.translate('understood'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 НОВОЕ: Открытие почтового клиента
  Future<void> _openEmailClient() async {
    final localizations = AppLocalizations.of(context);

    try {
      const emailUrl = 'mailto:support@driftnotes.app?subject=Вопрос по подписке Drift Notes&body=Здравствуйте! У меня есть вопрос по подписке:';
      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        Navigator.pop(context); // Закрываем диалог после открытия почты
      } else {
        _showErrorSnackBar(localizations.translate('failed_to_open_email'));
      }
    } catch (e) {
      _showErrorSnackBar(localizations.translate('email_open_error'));
    }
  }

  /// Показ ошибки через SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 🔧 ИСПРАВЛЕНО: Локализованное форматирование даты с родительным падежом
  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context).translate('not_specified');

    final localizations = AppLocalizations.of(context);

    // Получаем название месяца в родительном падеже для русского
    final monthNames = [
      'january_genitive', 'february_genitive', 'march_genitive', 'april_genitive',
      'may_genitive', 'june_genitive', 'july_genitive', 'august_genitive',
      'september_genitive', 'october_genitive', 'november_genitive', 'december_genitive'
    ];

    final monthName = localizations.translate(monthNames[date.month - 1]);
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $monthName $year, $hour:$minute';
  }

  /// 🔧 ИСПРАВЛЕНО: Определение типа подписки с fallback логикой
  String _getSubscriptionTypeName(SubscriptionModel subscription) {
    final localizations = AppLocalizations.of(context);

    // 1. Если type указан явно - используем его
    if (subscription.type != null) {
      switch (subscription.type!) {
        case SubscriptionType.monthly:
          return localizations.translate('monthly_subscription');
        case SubscriptionType.yearly:
          return localizations.translate('yearly_subscription');
      }
    }

    // 2. Пытаемся определить по productId
    if (subscription.productId != null) {
      if (subscription.productId!.contains('monthly')) {
        return localizations.translate('monthly_subscription');
      } else if (subscription.productId!.contains('yearly')) {
        return localizations.translate('yearly_subscription');
      }
    }

    // 3. Определяем по currentProductId (вычисляемое свойство)
    final currentProductId = subscription.currentProductId;
    if (currentProductId != null) {
      if (currentProductId == SubscriptionConstants.monthlyPremiumId) {
        return localizations.translate('monthly_subscription');
      } else if (currentProductId == SubscriptionConstants.yearlyPremiumId) {
        return localizations.translate('yearly_subscription');
      }
    }

    // 4. Определяем по дате истечения (приблизительно)
    if (subscription.expirationDate != null && subscription.createdAt != null) {
      final duration = subscription.expirationDate!.difference(subscription.createdAt!);
      if (duration.inDays > 200) { // Больше 6-7 месяцев = годовая
        return localizations.translate('yearly_subscription');
      } else if (duration.inDays > 20) { // Больше 20 дней = месячная
        return localizations.translate('monthly_subscription');
      }
    }

    // 5. Fallback - для тестовых аккаунтов показываем "Тестовая"
    if (subscription.purchaseToken?.contains('test') == true) {
      return localizations.translate('test_subscription');
    }

    return localizations.translate('not_specified');
  }

  /// Получение иконки статуса подписки
  IconData _getStatusIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Icons.check_circle;
      case SubscriptionStatus.expired:
        return Icons.error;
      case SubscriptionStatus.canceled:
        return Icons.cancel;
      case SubscriptionStatus.pending:
        return Icons.pending;
      case SubscriptionStatus.none:
        return Icons.help_outline;
    }
  }

  /// Получение цвета статуса подписки
  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.canceled:
        return Colors.orange;
      case SubscriptionStatus.pending:
        return Colors.blue;
      case SubscriptionStatus.none:
        return Colors.grey;
    }
  }

  /// Получение текста статуса подписки
  String _getStatusText(SubscriptionStatus status, bool isActive) {
    final localizations = AppLocalizations.of(context);

    if (status == SubscriptionStatus.active && isActive) {
      return localizations.translate('active');
    }

    switch (status) {
      case SubscriptionStatus.active:
        return localizations.translate('expires');
      case SubscriptionStatus.expired:
        return localizations.translate('expired');
      case SubscriptionStatus.canceled:
        return localizations.translate('canceled');
      case SubscriptionStatus.pending:
        return localizations.translate('pending');
      case SubscriptionStatus.none:
        return localizations.translate('no_subscription');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('subscription_management'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          final subscription = provider.subscription;

          if (subscription == null) {
            return Center(
              child: Text(localizations.translate('failed_to_load')),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Карточка статуса подписки
                _buildSubscriptionStatusCard(subscription, localizations),

                const SizedBox(height: 24),

                // 🔧 УЛУЧШЕНО: Новый дизайн деталей подписки
                _buildSubscriptionDetailsCard(subscription, localizations),

                const SizedBox(height: 24),

                // 🔧 УЛУЧШЕНО: Новые действия без кнопки обновления
                _buildActionsSection(localizations),

                const SizedBox(height: 24),

                // Дополнительная информация
                _buildAdditionalInfoSection(localizations),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Карточка статуса подписки
  Widget _buildSubscriptionStatusCard(SubscriptionModel subscription, AppLocalizations localizations) {
    final status = subscription.status;
    final isActive = subscription.isActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(status),
            size: 48,
            color: _getStatusColor(status),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('premium_subscription'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusText(status, isActive),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subscription.expirationDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${localizations.translate('valid_until')} ${_formatDate(subscription.expirationDate)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔧 ПОЛНОСТЬЮ ПЕРЕДЕЛАНО: Красивые детали подписки без переносов
  Widget _buildSubscriptionDetailsCard(SubscriptionModel subscription, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('subscription_details'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 🔧 НОВОЕ: Вертикальное расположение без переносов
          _buildDetailItem(
            icon: Icons.card_membership,
            label: localizations.translate('tariff'),
            value: _getSubscriptionTypeName(subscription),
            color: Colors.amber,
          ),

          const SizedBox(height: 16),

          _buildDetailItem(
            icon: Icons.phone_android,
            label: localizations.translate('platform'),
            value: subscription.platform.toUpperCase(),
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          _buildDetailItem(
            icon: Icons.shopping_cart,
            label: localizations.translate('purchased'),
            value: _formatDate(subscription.createdAt),
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          _buildDetailItem(
            icon: Icons.update,
            label: localizations.translate('updated'),
            value: _formatDate(subscription.updatedAt),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  /// 🆕 НОВОЕ: Красивый элемент детали подписки
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔧 УЛУЧШЕНО: Действия без кнопки обновления + новая кнопка поддержки
  Widget _buildActionsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('actions'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Управление в Google Play
        _buildActionButton(
          icon: Icons.settings,
          title: localizations.translate('manage_in_google_play'),
          subtitle: localizations.translate('change_plan_cancel_update'),
          color: Colors.green,
          onTap: _openGooglePlaySubscriptions,
        ),

        const SizedBox(height: 12),

        // Инструкция по отмене
        _buildActionButton(
          icon: Icons.help_outline,
          title: localizations.translate('how_to_cancel'),
          subtitle: localizations.translate('step_by_step_guide'),
          color: Colors.orange,
          onTap: _showCancelInstructionDialog,
        ),

        const SizedBox(height: 12),

        // 🆕 НОВОЕ: Связаться с поддержкой вместо обновления
        _buildActionButton(
          icon: Icons.support_agent,
          title: localizations.translate('support'),
          subtitle: localizations.translate('get_subscription_help'),
          color: Colors.blue,
          onTap: _showSupportDialog,
        ),
      ],
    );
  }

  /// 🔧 УЛУЧШЕНО: Кнопка действия с цветовой индикацией
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Секция дополнительной информации
  Widget _buildAdditionalInfoSection(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('important_info'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoItem(
            '✅',
            localizations.translate('premium_benefits'),
            localizations.translate('premium_benefits_list'),
          ),

          const SizedBox(height: 16),

          _buildInfoItem(
            '❓',
            localizations.translate('faq'),
            localizations.translate('faq_list'),
          ),
        ],
      ),
    );
  }

  /// Элемент дополнительной информации
  Widget _buildInfoItem(String emoji, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}