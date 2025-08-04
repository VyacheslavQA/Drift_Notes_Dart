// Путь: lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/paywall_screen.dart';
import 'language_settings_screen.dart';
import 'change_password_screen.dart';
import 'weather_notifications_settings_screen.dart';
import 'notification_sound_settings_screen.dart';
import 'weather_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {

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

            // Подписка
            _buildSectionHeader(localizations.translate('subscription')),
            Consumer<SubscriptionProvider>(
              builder: (context, provider, child) {
                return Card(
                  color: AppConstants.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      provider.isPremium ? Icons.diamond : Icons.diamond_outlined,
                      color: provider.isPremium ? Colors.amber : Colors.grey,
                    ),
                    title: Text(
                      provider.isPremium
                          ? localizations.translate('premium_active')
                          : localizations.translate('upgrade_to_premium'),
                    ),
                    subtitle: Text(
                      provider.isPremium
                          ? localizations.translate('premium_active_desc')
                          : localizations.translate('unlock_all_features'),
                    ),
                    trailing: provider.isPremium
                        ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: provider.isPremium ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
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
}