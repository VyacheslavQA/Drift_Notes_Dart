// Путь: lib/screens/settings/accepted_agreements_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/user_consent_service.dart';
import '../../models/user_consent_models.dart';
import '../../screens/help/privacy_policy_screen.dart';
import '../../screens/help/terms_of_service_screen.dart';
import 'document_version_history_screen.dart';

class AcceptedAgreementsScreen extends StatefulWidget {
  const AcceptedAgreementsScreen({super.key});

  @override
  State<AcceptedAgreementsScreen> createState() => _AcceptedAgreementsScreenState();
}

class _AcceptedAgreementsScreenState extends State<AcceptedAgreementsScreen> {
  final UserConsentService _consentService = UserConsentService();

  bool _isLoading = true;
  bool _isProcessing = false;
  UserConsentStatus? _consentStatus;
  String _privacyPolicyVersion = '';
  String _termsOfServiceVersion = '';
  bool _hasUpdates = false;
  bool _isDependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    // НЕ вызываем _loadConsentStatus() здесь!
    // Перенесено в didChangeDependencies()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Выполняем инициализацию только один раз после того, как dependencies готовы
    if (!_isDependenciesInitialized) {
      _isDependenciesInitialized = true;
      _loadConsentStatus();
    }
  }

  Future<void> _loadConsentStatus() async {
    if (!mounted) return;

    try {
      // Теперь безопасно использовать AppLocalizations.of(context)
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      final status = await _consentService.getUserConsentStatus(languageCode);
      final privacyVersion = await _consentService.getCurrentPrivacyPolicyVersion(languageCode);
      final termsVersion = await _consentService.getCurrentTermsOfServiceVersion(languageCode);

      // Проверяем, есть ли обновления
      final isVersionCurrent = await _consentService.isConsentVersionCurrent(languageCode);

      debugPrint('📋 Загружен статус согласий: версия актуальна = $isVersionCurrent');

      if (mounted) {
        setState(() {
          _consentStatus = status;
          _privacyPolicyVersion = privacyVersion;
          _termsOfServiceVersion = termsVersion;
          _hasUpdates = !isVersionCurrent;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки статуса соглашений: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Принятие обновленных согласий с локализацией
  Future<void> _acceptUpdatedAgreements() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _consentService.saveUserConsents(
        privacyPolicyAccepted: true,
        termsOfServiceAccepted: true,
      );

      if (success) {
        debugPrint('✅ Обновленные согласия приняты успешно');

        // Перезагружаем статус
        await _loadConsentStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('agreements_updated_successfully') ?? 'Agreements updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(localizations.translate('agreement_save_failed') ?? 'Failed to save agreements');
      }
    } catch (e) {
      debugPrint('❌ Ошибка принятия согласий: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_updating_agreements') ?? 'Error updating agreements'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Отклонение обновленных согласий с локализацией
  Future<void> _declineUpdatedAgreements() async {
    final localizations = AppLocalizations.of(context);

    // Показываем диалог с предупреждением
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text(
          localizations.translate('limited_mode') ?? 'Limited Mode',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('limited_mode_warning') ?? 'If you don\'t accept the new version of agreements, the app will work in limited mode:\n\n✅ View existing notes\n❌ Create new notes\n❌ Editing\n❌ Synchronization\n\nYou can accept agreements at any time.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel') ?? 'Cancel',
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.translate('continue_limited') ?? 'Continue in Limited Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('🔒 Пользователь выбрал ограниченный режим');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('limited_mode_activated') ?? 'Limited mode activated'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context); // Возвращаемся к настройкам
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
          localizations.translate('accepted_agreements') ?? 'Accepted Agreements',
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
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryColor,
        ),
      )
          : _buildContent(localizations),
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    if (_consentStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('error_loading_consents') ?? 'Error loading agreements',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConsentStatus,
              child: Text(localizations.translate('try_again') ?? 'Try again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Уведомление об обновлениях с локализацией
        if (_hasUpdates) ...[
          _buildUpdateNotificationCard(localizations),
          const SizedBox(height: 16),
        ],

        // Общий статус
        _buildStatusCard(localizations),
        const SizedBox(height: 16),

        // Политика конфиденциальности
        _buildDocumentCard(
          title: localizations.translate('privacy_policy') ?? 'Privacy Policy',
          accepted: _consentStatus!.privacyPolicyAccepted,
          currentVersion: _privacyPolicyVersion,
          onTap: () => _showPrivacyPolicy(),
          onViewHistory: () => _showPrivacyPolicyHistory(),
          localizations: localizations,
        ),
        const SizedBox(height: 12),

        // Пользовательское соглашение
        _buildDocumentCard(
          title: localizations.translate('terms_of_service') ?? 'Terms of Service',
          accepted: _consentStatus!.termsOfServiceAccepted,
          currentVersion: _termsOfServiceVersion,
          onTap: () => _showTermsOfService(),
          onViewHistory: () => _showTermsOfServiceHistory(),
          localizations: localizations,
        ),
        const SizedBox(height: 16),

        // Информация о версии
        _buildVersionInfo(localizations),
      ],
    );
  }

  /// Карточка уведомления об обновлениях с локализацией
  Widget _buildUpdateNotificationCard(AppLocalizations localizations) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('new_version_available') ?? 'New version available',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('update_agreements_description') ?? 'To continue full use of the app, you need to review and accept the updated agreements.',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _declineUpdatedAgreements,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      localizations.translate('limited_mode') ?? 'Limited Mode',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _acceptUpdatedAgreements,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      localizations.translate('accept_updates') ?? 'Accept Updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations localizations) {
    final hasAllConsents = _consentStatus!.hasAllConsents && !_hasUpdates;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasAllConsents ? Icons.check_circle : Icons.warning,
                  color: hasAllConsents ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasAllConsents
                        ? (localizations.translate('all_agreements_accepted') ?? 'All agreements accepted')
                        : (_hasUpdates
                        ? (localizations.translate('update_required') ?? 'Update required')
                        : (localizations.translate('agreements_require_attention') ?? 'Agreements require attention')),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!hasAllConsents) ...[
              const SizedBox(height: 8),
              Text(
                _hasUpdates
                    ? (localizations.translate('please_review_updated_agreements') ?? 'Please review the updated agreements')
                    : (localizations.translate('please_review_and_accept') ?? 'Please review and accept agreements'),
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required bool accepted,
    required String currentVersion,
    required VoidCallback onTap,
    required VoidCallback onViewHistory,
    required AppLocalizations localizations,
  }) {
    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              title,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      accepted ? Icons.check_circle : Icons.cancel,
                      color: accepted ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      accepted
                          ? (localizations.translate('accepted') ?? 'Accepted')
                          : (localizations.translate('not_accepted') ?? 'Not accepted'),
                      style: TextStyle(
                        color: accepted ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizations.translate('version') ?? 'Version'}: $currentVersion',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (_consentStatus!.consentTimestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.translate('accepted_date') ?? 'Accepted date'}: ${_formatDate(_consentStatus!.consentTimestamp!)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textColor.withOpacity(0.5),
              size: 16,
            ),
            onTap: onTap,
          ),

          // ИСПРАВЛЕНО: Кнопка "История версий" с локализацией
          const Divider(height: 1, color: Colors.white10),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              Icons.history,
              color: AppConstants.textColor.withOpacity(0.7),
              size: 20,
            ),
            title: Text(
              localizations.translate('version_history') ?? 'Version History',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textColor.withOpacity(0.5),
              size: 14,
            ),
            onTap: onViewHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(AppLocalizations localizations) {
    // ИСПРАВЛЕНИЕ: Используем текущий язык интерфейса, а не сохраненный язык согласий
    final currentLanguageCode = localizations.locale.languageCode;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('version_info') ?? 'Version Information',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              localizations.translate('consent_version') ?? 'Consent version',
              _consentStatus!.consentVersion ?? (localizations.translate('not_specified') ?? 'Not specified'),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('current_version') ?? 'Current version',
              _consentStatus!.currentVersion ?? (localizations.translate('unknown') ?? 'Unknown'),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('language') ?? 'Language',
              // ИСПРАВЛЕНО: Показываем текущий язык интерфейса, а не сохраненный
              _getLanguageDisplayName(currentLanguageCode),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('version_status') ?? 'Version status',
              !_hasUpdates
                  ? (localizations.translate('current') ?? 'Current')
                  : (localizations.translate('outdated') ?? 'Outdated'),
              localizations,
            ),
          ],
        ),
      ),
    );
  }

  /// Получает читаемое название языка
  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ru':
        return 'Русский (ru)';
      case 'en':
        return 'English (en)';
      default:
        return languageCode.toUpperCase();
    }
  }

  Widget _buildInfoRow(String label, String value, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _showPrivacyPolicyHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DocumentVersionHistoryScreen(
          documentType: 'privacy_policy',
        ),
      ),
    );
  }

  void _showTermsOfServiceHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DocumentVersionHistoryScreen(
          documentType: 'terms_of_service',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}