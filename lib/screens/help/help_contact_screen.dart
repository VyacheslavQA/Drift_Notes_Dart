// Путь: lib/screens/help/help_contact_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/user_consent_service.dart';
import '../settings/document_version_history_screen.dart';
import '../settings/accepted_agreements_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'user_guide_screen.dart';

class HelpContactScreen extends StatefulWidget {
  const HelpContactScreen({super.key});

  @override
  State<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends State<HelpContactScreen> {
  // Константы приложения (легко изменяемые)
  static const String appVersion = '1.0.0';
  static const String appSize = '25.4 МБ';
  static const String supportEmail = 'support@driftnotesapp.com';

  final UserConsentService _consentService = UserConsentService();
  bool _hasAgreementUpdates = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAgreementUpdates();
  }

  Future<void> _checkAgreementUpdates() async {
    try {
      final isVersionCurrent = await _consentService.isConsentVersionCurrent();
      if (mounted) {
        setState(() {
          _hasAgreementUpdates = !isVersionCurrent;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка проверки обновлений соглашений: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('help_contact'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.backgroundColor,
              AppConstants.backgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о приложении - компактное расположение
                _buildCompactAppInfoSection(localizations),

                const SizedBox(height: 24),

                // Кнопка руководства пользователя
                _buildUserGuideButton(context, localizations),

                const SizedBox(height: 16),

                // НОВАЯ КНОПКА: Принятые соглашения
                _buildAcceptedAgreementsButton(context, localizations),

                const SizedBox(height: 16),

                // Кнопка пользовательского соглашения
                _buildTermsOfServiceButton(context, localizations),

                const SizedBox(height: 16),

                // Кнопка политики конфиденциальности
                _buildPrivacyPolicyButton(context, localizations),

                const SizedBox(height: 16),

                // Кнопка истории версий документов
                _buildDocumentVersionHistoryButton(context, localizations),

                const SizedBox(height: 32),

                // Текст обратной связи
                _buildContactSection(localizations),

                const SizedBox(height: 24),

                // Кнопка связаться с нами
                _buildContactButton(context, localizations),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAppInfoSection(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Только логотип без контейнера
          Image.asset(
            'assets/images/app_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 20),

          // Информация справа
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название приложения
                Text(
                  'Drift Notes',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Версия и размер в строку
                Row(
                  children: [
                    // Версия
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('version'),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            appVersion,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Размер
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('size'),
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            appSize,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGuideButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUserGuide(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.translate('user_guide'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// НОВЫЙ ВИДЖЕТ: Кнопка принятых соглашений с уведомлениями
  Widget _buildAcceptedAgreementsButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasAgreementUpdates
              ? Colors.orange.withOpacity(0.5)
              : AppConstants.textColor.withValues(alpha: 0.1),
          width: _hasAgreementUpdates ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AcceptedAgreementsScreen(),
              ),
            );

            // Обновляем статус после возвращения
            _checkAgreementUpdates();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hasAgreementUpdates
                            ? Colors.orange.withOpacity(0.2)
                            : AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: _hasAgreementUpdates ? Colors.orange : AppConstants.textColor,
                        size: 24,
                      ),
                    ),
                    // Красная точка уведомления
                    if (_hasAgreementUpdates)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('accepted_agreements') ?? 'Принятые соглашения',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasAgreementUpdates
                            ? 'Доступна новая версия соглашений'
                            : 'Статус принятых соглашений',
                        style: TextStyle(
                          color: _hasAgreementUpdates
                              ? Colors.orange
                              : AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: _hasAgreementUpdates ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasAgreementUpdates)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsOfServiceButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openTermsOfService(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.translate('terms_of_service'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPrivacyPolicy(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    localizations.translate('privacy_policy'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Кнопка истории версий документов
  Widget _buildDocumentVersionHistoryButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDocumentVersionsMenu(context, localizations),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('version_history') ?? 'История версий',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Просмотр изменений в документах',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Показывает меню выбора документа для просмотра истории версий
  void _showDocumentVersionsMenu(BuildContext context, AppLocalizations localizations) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.translate('version_history') ?? 'История версий',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Выберите документ для просмотра истории версий',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Политика конфиденциальности
            _buildDocumentHistoryOption(
              context,
              localizations,
              title: localizations.translate('privacy_policy') ?? 'Политика конфиденциальности',
              description: 'Просмотр истории изменений политики конфиденциальности',
              icon: Icons.security,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentVersionHistoryScreen(
                      documentType: 'privacy_policy',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Пользовательское соглашение
            _buildDocumentHistoryOption(
              context,
              localizations,
              title: localizations.translate('terms_of_service') ?? 'Пользовательское соглашение',
              description: 'Просмотр истории изменений пользовательского соглашения',
              icon: Icons.description,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentVersionHistoryScreen(
                      documentType: 'terms_of_service',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Опция для выбора документа
  Widget _buildDocumentHistoryOption(
      BuildContext context,
      AppLocalizations localizations, {
        required String title,
        required String description,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.textColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textColor.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('contact_us_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          localizations.translate('contact_us_text'),
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          supportEmail,
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(BuildContext context, AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _sendEmail(context),
        icon: Icon(
          Icons.email_outlined,
          color: AppConstants.textColor,
        ),
        label: Text(
          localizations.translate('contact_us_button'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _openUserGuide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserGuideScreen(),
      ),
    );
  }

  void _openTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final localizations = AppLocalizations.of(context);

    final subject = Uri.encodeComponent(localizations.translate('email_subject'));
    final body = Uri.encodeComponent(localizations.translate('email_body'));

    final emailUrl = 'mailto:$supportEmail?subject=$subject&body=$body';

    try {
      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('email_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}