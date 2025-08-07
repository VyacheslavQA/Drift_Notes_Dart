// Путь: lib/screens/help/help_contact_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
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
  static const String appVersion = '1.0.0';
  static const String appSize = '25.4 МБ';
  static const String supportEmail = 'support@driftnotesapp.com';

  final UserConsentService _consentService = UserConsentService();
  bool _hasAgreementUpdates = false;
  bool _isLoading = true;
  bool _isDependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDependenciesInitialized) {
      _isDependenciesInitialized = true;
      _checkAgreementUpdates();
    }
  }

  Future<void> _checkAgreementUpdates() async {
    if (!mounted) return;

    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final consentResult = await _consentService.checkUserConsents(
        languageCode,
      );

      if (mounted) {
        setState(() {
          _hasAgreementUpdates = consentResult.hasChanges;
          _isLoading = false;
        });

        debugPrint(
          '📋 Проверка обновлений в Help: hasChanges=${consentResult.hasChanges}',
        );
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
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('help_contact'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 18 : (isTablet ? 24 : 22),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isTablet ? kToolbarHeight + 8 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: isSmallScreen ? 24 : 28,
          ),
          onPressed: () => Navigator.pop(context),
          constraints: BoxConstraints(
            minWidth: ResponsiveConstants.minTouchTarget,
            minHeight: ResponsiveConstants.minTouchTarget,
          ),
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о приложении - адаптивная
                _buildCompactAppInfoSection(localizations),

                SizedBox(height: ResponsiveConstants.spacingL),

                // Кнопка руководства пользователя
                _buildUserGuideButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingM),

                // Кнопка принятых соглашений
                _buildAcceptedAgreementsButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingM),

                // Кнопка пользовательского соглашения
                _buildTermsOfServiceButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingM),

                // Кнопка политики конфиденциальности
                _buildPrivacyPolicyButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingM),

                // Кнопка истории версий документов
                _buildDocumentVersionHistoryButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingXL),

                // Текст обратной связи
                _buildContactSection(localizations),

                SizedBox(height: ResponsiveConstants.spacingL),

                // Кнопка связаться с нами
                _buildContactButton(context, localizations),

                SizedBox(height: ResponsiveConstants.spacingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAppInfoSection(AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Верхняя часть - логотип и название на одном уровне
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Выравниваем по центру
            children: [
              // Логотип слева
              Image.asset(
                'assets/images/app_logo.png',
                width: isSmallScreen ? 60 : (isTablet ? 80 : 70),
                height: isSmallScreen ? 60 : (isTablet ? 80 : 70),
                fit: BoxFit.contain,
              ),
              SizedBox(width: ResponsiveConstants.spacingM),
              // Название справа, выровнено по центру логотипа
              Expanded(
                child: Text(
                  'Drift Notes',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: isSmallScreen ? 18 : (isTablet ? 26 : 22),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveConstants.spacingM),

          // Нижняя часть - версия и размер под логотипом и названием
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12), // Добавляем отступы слева и справа
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    localizations.translate('version'),
                    appVersion,
                    isSmallScreen,
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: _buildInfoColumn(
                    localizations.translate('size'),
                    appSize,
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: isSmall ? 10 : 12,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmall ? 12 : 14, // Уменьшили размер
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildUserGuideButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return _buildMenuButton(
      icon: Icons.help_outline,
      title: localizations.translate('user_guide') ?? 'Руководство пользователя',
      onTap: () => _openUserGuide(context),
    );
  }

  Widget _buildAcceptedAgreementsButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
            _checkAgreementUpdates();
          },
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: isSmallScreen ? 40 : 48,
                      height: isSmallScreen ? 40 : 48,
                      decoration: BoxDecoration(
                        color: _hasAgreementUpdates
                            ? Colors.orange.withOpacity(0.2)
                            : AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: _hasAgreementUpdates
                            ? Colors.orange
                            : AppConstants.textColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    if (_hasAgreementUpdates)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: isSmallScreen ? 10 : 12,
                          height: isSmallScreen ? 10 : 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('accepted_agreements') ??
                            'Принятые соглашения',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: isSmallScreen ? 13 : 15, // Уменьшили
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Увеличили до 2 строк
                      ),
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        _hasAgreementUpdates
                            ? (localizations.translate(
                            'new_agreement_version_available') ??
                            'Доступна новая версия соглашений')
                            : (localizations.translate('agreement_status') ??
                            'Статус принятых соглашений'),
                        style: TextStyle(
                          color: _hasAgreementUpdates
                              ? Colors.orange
                              : AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: _hasAgreementUpdates
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasAgreementUpdates)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(width: ResponsiveConstants.spacingS),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      size: isSmallScreen ? 14 : 16,
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

  Widget _buildTermsOfServiceButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return _buildMenuButton(
      icon: Icons.description_outlined,
      title: localizations.translate('terms_of_service') ??
          'Пользовательское соглашение',
      onTap: () => _openTermsOfService(context),
    );
  }

  Widget _buildPrivacyPolicyButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    return _buildMenuButton(
      icon: Icons.privacy_tip_outlined,
      title: localizations.translate('privacy_policy') ??
          'Политика конфиденциальности',
      onTap: () => _openPrivacyPolicy(context),
    );
  }

  Widget _buildDocumentVersionHistoryButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDocumentVersionsMenu(context, localizations),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 40 : 48,
                  height: isSmallScreen ? 40 : 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppConstants.textColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('version_history') ??
                            'История версий',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: ResponsiveConstants.spacingXS),
                      Text(
                        localizations.translate('version_history_description') ??
                            'Просмотр изменений в документах',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: isSmallScreen ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Универсальный виджет для простых кнопок меню
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: AppConstants.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 40 : 48,
                  height: isSmallScreen ? 40 : 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.textColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: ResponsiveConstants.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isSmallScreen ? 13 : 15, // Уменьшили размер
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // Больше строк для переноса
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.textColor.withValues(alpha: 0.6),
                  size: isSmallScreen ? 14 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentVersionsMenu(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 16 : 20,
            right: isSmallScreen ? 16 : 20,
            top: isSmallScreen ? 16 : 20,
            // Умеренный отступ снизу
            bottom: (isSmallScreen ? 16 : 20) + 8,
          ),
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
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: ResponsiveConstants.spacingM),
                  Expanded(
                    child: Text(
                      localizations.translate('version_history') ??
                          'История версий',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveConstants.spacingS),

              Text(
                localizations.translate('select_document_for_history') ??
                    'Выберите документ для просмотра истории версий',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: ResponsiveConstants.spacingL),

              // Политика конфиденциальности
              _buildDocumentHistoryOption(
                context,
                localizations,
                title: localizations.translate('privacy_policy') ??
                    'Политика конфиденциальности',
                description: localizations
                    .translate('privacy_policy_history_description') ??
                    'Просмотр истории изменений политики конфиденциальности',
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

              SizedBox(height: ResponsiveConstants.spacingM),

              // Пользовательское соглашение
              _buildDocumentHistoryOption(
                context,
                localizations,
                title: localizations.translate('terms_of_service') ??
                    'Пользовательское соглашение',
                description:
                localizations.translate('terms_history_description') ??
                    'Просмотр истории изменений пользовательского соглашения',
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

              // Небольшой дополнительный отступ в конце
              SizedBox(height: ResponsiveConstants.spacingM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentHistoryOption(
      BuildContext context,
      AppLocalizations localizations, {
        required String title,
        required String description,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: isSmallScreen ? 16 : 20,
              ),
            ),

            SizedBox(width: ResponsiveConstants.spacingM),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: ResponsiveConstants.spacingXS),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.6),
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textColor.withValues(alpha: 0.3),
              size: isSmallScreen ? 12 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations localizations) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('contact_us_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 16 : (isTablet ? 22 : 20),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2, // Увеличили до 2 строк
        ),
        SizedBox(height: ResponsiveConstants.spacingM),
        Text(
          localizations.translate('contact_us_text'),
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.8),
            fontSize: isSmallScreen ? 13 : 15, // Уменьшили размер
            height: 1.4, // Уменьшили межстрочный интервал
          ),
          maxLines: isSmallScreen ? 6 : null, // Больше строк
          overflow: isSmallScreen ? TextOverflow.ellipsis : null,
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
        // Email в отдельном контейнере для лучшего переноса
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              supportEmail,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: isSmallScreen ? 11 : 13, // Еще меньше
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(
      BuildContext context,
      AppLocalizations localizations,
      ) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Container(
      width: double.infinity,
      height: ResponsiveConstants.minTouchTarget,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () => _sendEmail(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              color: AppConstants.textColor,
              size: isSmallScreen ? 18 : 20,
            ),
            SizedBox(width: ResponsiveConstants.spacingS),
            Flexible(
              child: Text(
                localizations.translate('contact_us_button'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: isSmallScreen ? 14 : 16, // Уменьшили размер
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUserGuide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserGuideScreen()),
    );
  }

  void _openTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final localizations = AppLocalizations.of(context);

    final subject = Uri.encodeComponent(
      localizations.translate('email_subject'),
    );
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