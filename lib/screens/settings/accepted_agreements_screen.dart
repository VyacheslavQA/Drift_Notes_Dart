// Путь: lib/screens/settings/accepted_agreements_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/user_consent_service.dart';
import '../../models/user_consent_models.dart';
import '../../screens/help/privacy_policy_screen.dart';
import '../../screens/help/terms_of_service_screen.dart';
import 'document_version_history_screen.dart';
import '../../widgets/user_agreements_dialog.dart';

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
  ConsentCheckResult? _consentResult; // Результат селективной проверки
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

      // ИСПРАВЛЕНО: Сначала загружаем селективную проверку (основные данные)
      final consentResult = await _consentService.checkUserConsents(languageCode);

      // Затем загружаем статус для дополнительной информации (timestamp и т.д.)
      var status = await _consentService.getUserConsentStatus(languageCode);

      final privacyVersion = await _consentService.getCurrentPrivacyPolicyVersion(languageCode);
      final termsVersion = await _consentService.getCurrentTermsOfServiceVersion(languageCode);

      // ПРИНУДИТЕЛЬНАЯ СИНХРОНИЗАЦИЯ при частичных обновлениях
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && consentResult.hasChanges && !consentResult.allValid) {
        debugPrint('🔄 Принудительная синхронизация локальных данных с Firebase');
        await _consentService.syncConsentsFromFirestore(user.uid);

        // Перезагружаем статус после синхронизации
        final statusAfterSync = await _consentService.getUserConsentStatus(languageCode);
        debugPrint('📋 Статус после синхронизации: Privacy=${statusAfterSync.privacyPolicyAccepted}, Terms=${statusAfterSync.termsOfServiceAccepted}');

        // Обновляем переменную status
        status = statusAfterSync;
      }

      // ОТЛАДОЧНЫЕ ЛОГИ
      debugPrint('📋 Загружен статус согласий: $consentResult');
      debugPrint('🔍 ДЕТАЛЬНАЯ ДИАГНОСТИКА:');
      debugPrint('   privacyPolicyAccepted: ${status.privacyPolicyAccepted}');
      debugPrint('   termsOfServiceAccepted: ${status.termsOfServiceAccepted}');
      debugPrint('   needPrivacyPolicy: ${consentResult.needPrivacyPolicy}');
      debugPrint('   needTermsOfService: ${consentResult.needTermsOfService}');
      debugPrint('   allValid: ${consentResult.allValid}');
      debugPrint('   hasChanges: ${consentResult.hasChanges}');
      debugPrint('   Privacy: current=${consentResult.currentPrivacyVersion}, saved=${consentResult.savedPrivacyVersion}');
      debugPrint('   Terms: current=${consentResult.currentTermsVersion}, saved=${consentResult.savedTermsVersion}');

      if (mounted) {
        setState(() {
          _consentStatus = status;
          _consentResult = consentResult;
          _privacyPolicyVersion = privacyVersion;
          _termsOfServiceVersion = termsVersion;
          _hasUpdates = consentResult.hasChanges; // Используем селективную проверку
          _isLoading = false;
        });

        // ДОПОЛНИТЕЛЬНЫЕ ЛОГИ ПОСЛЕ ОБНОВЛЕНИЯ СОСТОЯНИЯ
        debugPrint('🎯 СОСТОЯНИЕ ЭКРАНА ОБНОВЛЕНО:');
        debugPrint('   _hasUpdates: $_hasUpdates');
        debugPrint('   Privacy версия: $_privacyPolicyVersion');
        debugPrint('   Terms версия: $_termsOfServiceVersion');
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

  // Показывает диалог селективного принятия согласий
  Future<void> _showSelectiveAgreementsDialog() async {
    if (_consentResult == null || !_consentResult!.hasChanges) {
      debugPrint('⚠️ Попытка показать диалог когда нет изменений');
      return;
    }

    debugPrint('📱 Показываем селективный диалог согласий');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserAgreementsDialog(
        onAgreementsAccepted: () {
          debugPrint('✅ Согласия приняты селективно, перезагружаем статус');
          _loadConsentStatus(); // Перезагружаем статус
        },
        onCancel: () {
          debugPrint('❌ Пользователь отменил принятие согласий');
        },
      ),
    );
  }

  /// УСТАРЕВШИЙ МЕТОД: Принятие всех согласий (для обратной совместимости)
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
              content: Text(localizations.translate('agreements_updated_successfully') ?? 'Соглашения успешно обновлены'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(localizations.translate('agreement_save_failed') ?? 'Не удалось сохранить соглашения');
      }
    } catch (e) {
      debugPrint('❌ Ошибка принятия согласий: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_updating_agreements') ?? 'Ошибка обновления соглашений'}: $e'),
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
          localizations.translate('limited_mode') ?? 'Ограниченный режим',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('limited_mode_warning') ??
              'Если вы не примете новую версию соглашений, приложение будет работать в ограниченном режиме:\n\n✅ Просмотр существующих записей\n❌ Создание новых записей\n❌ Редактирование\n❌ Синхронизация\n\nВы можете принять соглашения в любое время.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel') ?? 'Отмена',
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.translate('continue_limited') ?? 'Продолжить в ограниченном режиме'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('🔒 Пользователь выбрал ограниченный режим');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('limited_mode_activated') ?? 'Ограниченный режим активирован'),
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
          localizations.translate('accepted_agreements') ?? 'Принятые соглашения',
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
    if (_consentStatus == null || _consentResult == null) {
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
              localizations.translate('error_loading_consents') ?? 'Ошибка загрузки соглашений',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConsentStatus,
              child: Text(localizations.translate('try_again') ?? 'Попробовать снова'),
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

        // ИСПРАВЛЕНО: Политика конфиденциальности с селективным статусом
        _buildDocumentCard(
          title: localizations.translate('privacy_policy') ?? 'Политика конфиденциальности',
          accepted: _consentStatus!.privacyPolicyAccepted,
          needsUpdate: _consentResult!.needPrivacyPolicy,
          currentVersion: _privacyPolicyVersion,
          savedVersion: _consentResult!.savedPrivacyVersion,
          onTap: () => _showPrivacyPolicy(),
          onViewHistory: () => _showPrivacyPolicyHistory(),
          localizations: localizations,
        ),
        const SizedBox(height: 12),

        // ИСПРАВЛЕНО: Пользовательское соглашение с селективным статусом
        _buildDocumentCard(
          title: localizations.translate('terms_of_service') ?? 'Пользовательское соглашение',
          accepted: _consentStatus!.termsOfServiceAccepted,
          needsUpdate: _consentResult!.needTermsOfService,
          currentVersion: _termsOfServiceVersion,
          savedVersion: _consentResult!.savedTermsVersion,
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

  /// Карточка уведомления об обновлениях с селективной кнопкой
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
                    localizations.translate('new_version_available') ?? 'Доступна новая версия',
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

            // Показываем что именно обновилось
            Text(
              _getUpdateDescription(localizations),
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
                      localizations.translate('limited_mode') ?? 'Ограниченный режим',
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
                    // Используем селективный диалог вместо принятия всего
                    onPressed: _isProcessing ? null : _showSelectiveAgreementsDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      localizations.translate('accept_updates') ?? 'Принять обновления',
                      style: const TextStyle(
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

  // Генерирует описание того, что обновилось
  String _getUpdateDescription(AppLocalizations localizations) {
    if (_consentResult == null) return '';

    List<String> updates = [];

    if (_consentResult!.needPrivacyPolicy) {
      updates.add(localizations.translate('privacy_policy_update_desc') ?? 'политика конфиденциальности');
    }

    if (_consentResult!.needTermsOfService) {
      updates.add(localizations.translate('terms_update_desc') ?? 'пользовательское соглашение');
    }

    if (updates.isEmpty) {
      return localizations.translate('agreements_needed_general') ?? 'Для продолжения работы необходимо принять соглашения.';
    } else if (updates.length == 1) {
      return localizations.translate('single_agreement_update')?.replaceAll('{document}', updates[0]) ??
          'Обновилась ${updates[0]}. Для продолжения работы необходимо принять новую версию.';
    } else {
      return localizations.translate('multiple_agreements_updated')?.replaceAll('{documents}', updates.join(' и ')) ??
          'Обновились ${updates.join(' и ')}. Для продолжения работы необходимо принять новые версии.';
    }
  }

  Widget _buildStatusCard(AppLocalizations localizations) {
    final hasAllConsents = _consentResult!.allValid;

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
                        ? (localizations.translate('all_agreements_accepted') ?? 'Все соглашения приняты')
                        : (_hasUpdates
                        ? (localizations.translate('update_required') ?? 'Требуется обновление')
                        : (localizations.translate('agreements_require_attention') ?? 'Соглашения требуют внимания')),
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
                    ? (localizations.translate('please_review_updated_agreements') ?? 'Пожалуйста, ознакомьтесь с обновленными соглашениями')
                    : (localizations.translate('please_review_and_accept') ?? 'Пожалуйста, ознакомьтесь и примите соглашения'),
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

  // ИСПРАВЛЕННЫЙ МЕТОД: Карточка документа с селективным статусом
  Widget _buildDocumentCard({
    required String title,
    required bool accepted,
    required bool needsUpdate, // Селективная проверка
    required String currentVersion,
    String? savedVersion, // Сохраненная версия
    required VoidCallback onTap,
    required VoidCallback onViewHistory,
    required AppLocalizations localizations,
  }) {
    // ПРАВИЛЬНАЯ ЛОГИКА: Определяем статус документа
    Color statusColor;
    IconData statusIcon;
    String statusText;

    debugPrint('🔍 Статус карточки "$title": accepted=$accepted, needsUpdate=$needsUpdate');

    if (!accepted) {
      // Документ вообще не принят
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = localizations.translate('not_accepted') ?? 'Не принято';
    } else if (needsUpdate) {
      // Документ принят, но требует обновления
      statusColor = Colors.orange;
      statusIcon = Icons.update;
      statusText = localizations.translate('update_required') ?? 'Требуется обновление';
    } else {
      // Документ принят и актуален
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = localizations.translate('accepted') ?? 'Принято';
    }

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
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizations.translate('version') ?? 'Версия'}: $currentVersion',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                // Показываем информацию о версиях если есть обновление
                if (needsUpdate && savedVersion != null && savedVersion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${localizations.translate('accepted_version') ?? 'Принята версия'}: $savedVersion → $currentVersion',
                    style: TextStyle(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (_consentStatus!.consentTimestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.translate('accepted_date') ?? 'Дата принятия'}: ${_formatDate(_consentStatus!.consentTimestamp!)}',
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

          // Кнопка "История версий"
          const Divider(height: 1, color: Colors.white10),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              Icons.history,
              color: AppConstants.textColor.withOpacity(0.7),
              size: 20,
            ),
            title: Text(
              localizations.translate('version_history') ?? 'История версий',
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
              localizations.translate('version_info') ?? 'Информация о версии',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              localizations.translate('consent_version') ?? 'Версия согласий',
              _consentStatus!.consentVersion ?? (localizations.translate('not_specified') ?? 'Не указано'),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('current_version') ?? 'Текущая версия',
              _consentStatus!.currentVersion ?? (localizations.translate('unknown') ?? 'Неизвестно'),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('language') ?? 'Язык',
              _getLanguageDisplayName(currentLanguageCode),
              localizations,
            ),
            _buildInfoRow(
              localizations.translate('version_status') ?? 'Статус версии',
              !_hasUpdates
                  ? (localizations.translate('current') ?? 'Текущая')
                  : (localizations.translate('outdated') ?? 'Устаревшая'),
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