// Путь: lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/subscription_constants.dart';
import '../../localization/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../models/subscription_model.dart';
import '../subscription/paywall_screen.dart';
import '../subscription/subscription_management_screen.dart';
import 'language_settings_screen.dart';
import 'change_password_screen.dart';
import 'weather_notifications_settings_screen.dart';
import 'notification_sound_settings_screen.dart';
import 'weather_settings_screen.dart';
import '../../services/data_export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final DataExportService _exportService = DataExportService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('settings'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Настройки языка
            _buildSectionHeader(localizations.translate('language')),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: Text(localizations.translate('language')),
                subtitle: Text(localizations.translate('select_language')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🆕 ИСПРАВЛЕННАЯ СЕКЦИЯ ПОДПИСКИ
            _buildSectionHeader(localizations.translate('subscription')),
            Consumer<SubscriptionProvider>(
              builder: (context, provider, child) {
                final isPremium = provider.isPremium;
                final subscription = provider.subscription; // 🔧 ИСПРАВЛЕНО: использую subscription вместо currentSubscription

                return Card(
                  color: AppConstants.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isPremium
                        ? BorderSide(color: Colors.amber.withOpacity(0.3), width: 1)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPremium
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPremium ? Icons.diamond : Icons.diamond_outlined,
                        color: isPremium ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isPremium
                          ? localizations.translate('premium_active')
                          : localizations.translate('upgrade_to_premium'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isPremium
                          ? _getSubscriptionStatusText(subscription, localizations)
                          : localizations.translate('unlock_all_features'),
                      style: TextStyle(
                        color: isPremium ? Colors.green : Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(
                      isPremium ? Icons.settings : Icons.arrow_forward_ios,
                      color: isPremium ? Colors.white70 : Colors.white30,
                      size: isPremium ? 20 : 16,
                    ),
                    onTap: () {
                      if (isPremium) {
                        // 🆕 НОВОЕ: Открываем экран управления подпиской
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionManagementScreen(),
                          ),
                        );
                      } else {
                        // Открываем PaywallScreen для покупки
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaywallScreen(),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Уведомления
            _buildSectionHeader(localizations.translate('notifications')),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Настройки звуков уведомлений
                  ListTile(
                    leading: const Icon(Icons.volume_up, color: Colors.green),
                    title: Text(
                      AppLocalizations.of(context).translate('notification_sounds'),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).translate('sound_vibration_badge_settings'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSoundSettingsScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1, color: Colors.white10),

                  // Погодные уведомления
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active,
                      color: Colors.amber,
                    ),
                    title: Text(
                      localizations.translate('weather_notifications'),
                    ),
                    subtitle: Text(
                      localizations.translate('weather_notifications_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeatherNotificationsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Настройки погоды
            _buildSectionHeader(localizations.translate('weather_settings')),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue),
                title: Text(localizations.translate('weather_settings')),
                subtitle: Text(
                  localizations.translate('units_and_calibration'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeatherSettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Безопасность (только смена пароля)
            _buildSectionHeader(localizations.translate('security')),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.security, color: Colors.blue),
                title: Text(localizations.translate('change_password')),
                subtitle: Text(
                  localizations.translate('change_your_account_password'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🆕 ПЕРЕМЕЩЕННАЯ СЕКЦИЯ: ЭКСПОРТ ДАННЫХ
            _buildSectionHeader(localizations.translate('export_data') ?? 'Экспорт данных'),
            Card(
              color: AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  localizations.translate('export_my_data') ?? 'Экспорт моих данных',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  localizations.translate('download_all_your_data') ?? 'Скачать все ваши данные в ZIP архиве',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                trailing: _isExporting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
                    : const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 16,
                ),
                onTap: _isExporting ? null : _exportUserData,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ========================================
  // 🆕 НОВЫЙ МЕТОД: ЭКСПОРТ ДАННЫХ ПОЛЬЗОВАТЕЛЯ
  // ========================================

  Future<void> _exportUserData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final localizations = AppLocalizations.of(context);

      // Показываем диалог с информацией
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: Row(
            children: [
              const Icon(Icons.download, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                localizations.translate('exporting_data') ?? 'Экспорт данных',
                style: TextStyle(color: AppConstants.textColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('preparing_your_data') ?? 'Подготавливаем ваши данные...',
                style: TextStyle(color: AppConstants.textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Выполняем экспорт с локализацией
      final localizationMap = {
        'readme_title': localizations.translate('readme_title') ?? 'DRIFT NOTES - ЭКСПОРТ ДАННЫХ',
        'readme_export_date': localizations.translate('readme_export_date') ?? 'Дата экспорта:',
        'readme_user_id': localizations.translate('readme_user_id') ?? 'ID пользователя:',
        'readme_app_version': localizations.translate('readme_app_version') ?? 'Версия приложения:',
        'readme_export_version': localizations.translate('readme_export_version') ?? 'Версия экспорта:',
        'readme_archive_contents': localizations.translate('readme_archive_contents') ?? 'СОДЕРЖИМОЕ АРХИВА:',
        'readme_full_data': localizations.translate('readme_full_data') ?? 'Полные данные в JSON формате',
        'readme_fishing_notes': localizations.translate('readme_fishing_notes') ?? 'Заметки рыбалки',
        'readme_marker_maps': localizations.translate('readme_marker_maps') ?? 'Маркерные карты',
        'readme_budget_notes': localizations.translate('readme_budget_notes') ?? 'Заметки бюджета',
        'readme_detailed_expenses': localizations.translate('readme_detailed_expenses') ?? 'Детальные расходы по всем поездкам',
        'readme_description_file': localizations.translate('readme_description_file') ?? 'Этот файл с описанием',
        'readme_records': localizations.translate('readme_records') ?? 'записей',
        'readme_rights_gdpr': localizations.translate('readme_rights_gdpr') ?? 'ПРАВА И GDPR:',
        'readme_contains_all_data': localizations.translate('readme_contains_all_data') ?? 'Этот архив содержит ВСЕ ваши данные из приложения Drift Notes.',
        'readme_gdpr_compliance': localizations.translate('readme_gdpr_compliance') ?? 'Данные экспортированы в соответствии с требованиями GDPR.',
        'readme_data_usage': localizations.translate('readme_data_usage') ?? 'Вы можете использовать эти данные для переноса в другие приложения или для долгосрочного хранения.',
        'readme_technical_info': localizations.translate('readme_technical_info') ?? 'ТЕХНИЧЕСКАЯ ИНФОРМАЦИЯ:',
        'readme_json_description': localizations.translate('readme_json_description') ?? '• JSON файл содержит структурированные данные со всеми полями',
        'readme_csv_description': localizations.translate('readme_csv_description') ?? '• CSV файлы содержат основные поля для удобного просмотра',
        'readme_date_format': localizations.translate('readme_date_format') ?? '• Даты указаны в формате ISO 8601 (YYYY-MM-DDTHH:mm:ss.sssZ)',
        'readme_coordinates_format': localizations.translate('readme_coordinates_format') ?? '• Координаты указаны в десятичных градусах (WGS84)',
        'readme_contact': localizations.translate('readme_contact') ?? 'Контакт:',
        'readme_website': localizations.translate('readme_website') ?? 'Сайт:',
      };

      final success = await _exportService.exportAllUserData(localizationMap);

      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Показываем успешное сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.translate('data_exported_successfully') ??
                          'Данные успешно экспортированы и сохранены в папке Загрузки',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.translate('export_failed') ??
                          'Ошибка при экспорте данных. Попробуйте еще раз.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      // Закрываем диалог загрузки если он еще открыт
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ========================================
  // 🆕 ИСПРАВЛЕННЫЕ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Получение текста статуса подписки для отображения в настройках
  String _getSubscriptionStatusText(SubscriptionModel? subscription, AppLocalizations localizations) {
    if (subscription == null) return localizations.translate('status_unknown') ?? 'Статус неизвестен';

    if (subscription.isActive) {
      return localizations.translate('active_tap_to_manage') ?? 'Активна • Нажмите для управления';
    }

    switch (subscription.status) {
      case SubscriptionStatus.expired:
        return localizations.translate('expired_renew') ?? 'Истекла • Обновите подписку';
      case SubscriptionStatus.canceled:
        final dateText = _formatShortDate(subscription.expirationDate);
        return localizations.translate('canceled_until') ?? 'Отменена • Действует до $dateText';
      case SubscriptionStatus.pending:
        return localizations.translate('pending_payment') ?? 'Ожидает оплаты';
      case SubscriptionStatus.active:
        final dateText = _formatShortDate(subscription.expirationDate);
        return localizations.translate('expires_on') ?? 'Истекает • $dateText';
      case SubscriptionStatus.none: // 🔧 ДОБАВЛЕНО: обработка SubscriptionStatus.none
        return localizations.translate('no_subscription') ?? 'Нет подписки';
    }
  }

  /// Форматирование краткой даты
  String _formatShortDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) return 'истекла';
    if (difference == 0) return 'сегодня';
    if (difference == 1) return 'завтра';
    if (difference < 7) return '$difference дн.';

    try {
      return DateFormat('d MMM', 'ru_RU').format(date);
    } catch (e) {
      // Фоллбэк для случая если локализация недоступна
      return DateFormat('d MMM').format(date);
    }
  }
}