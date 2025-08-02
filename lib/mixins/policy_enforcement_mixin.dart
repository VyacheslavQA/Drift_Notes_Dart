// Путь: lib/mixins/policy_enforcement_mixin.dart

import 'package:flutter/material.dart';
import '../services/user_consent_service.dart';
import '../widgets/user_agreements_dialog.dart';
import '../localization/app_localizations.dart';
import '../constants/app_constants.dart';

/// ✅ СЕЛЕКТИВНЫЙ миксин для проверки согласий пользователя
/// УЛУЧШЕНИЕ: Добавлена поддержка селективного показа устаревших политик
mixin PolicyEnforcementMixin<T extends StatefulWidget> on State<T> {
  final UserConsentService _consentService = UserConsentService();
  // ✅ ИСПРАВЛЕНО: Убрал неиспользуемое поле _firebaseService

  bool _consentsChecked = false;
  bool _consentsValid = false;

  // ✅ НОВОЕ: Хранение результата последней проверки для селективности
  ConsentCheckResult? _lastConsentCheck;

  /// ✅ СЕЛЕКТИВНАЯ проверка согласий при инициализации
  Future<void> checkPolicyCompliance() async {
    if (_consentsChecked) return; // Избегаем повторных проверок

    try {
      debugPrint('📋 Проверяем согласия пользователя...');

      // ✅ СЕЛЕКТИВНАЯ проверка - получаем подробную информацию
      final consentResult = await _consentService.checkUserConsents();
      _lastConsentCheck = consentResult; // ✅ Сохраняем результат для использования
      _consentsChecked = true;
      _consentsValid = consentResult.allValid;

      if (!consentResult.allValid) {
        // ✅ ЛОГИРОВАНИЕ: Показываем что именно устарело
        final outdatedList = consentResult.outdatedPolicies;
        debugPrint('🚫 Согласия не приняты или устарели: $outdatedList');
        debugPrint('📋 Privacy Policy нужно: ${consentResult.needPrivacyPolicy}');
        debugPrint('📋 Terms of Service нужно: ${consentResult.needTermsOfService}');

        // ✅ СЕЛЕКТИВНЫЙ показ диалога
        await _showSelectivePolicyDialog(consentResult);
      } else {
        debugPrint('✅ Все согласия актуальны');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      _consentsChecked = true;
      _consentsValid = false;
      // В случае ошибки показываем диалог для безопасности (полный)
      await _showFallbackPolicyDialog();
    }
  }

  /// ✅ НОВЫЙ: Селективный показ диалога только с устаревшими политиками
  Future<void> _showSelectivePolicyDialog(ConsentCheckResult consentResult) async {
    if (!mounted) return;

    final outdatedPolicies = consentResult.outdatedPolicies;

    // ✅ СЕЛЕКТИВНЫЕ параметры для диалога
    final showPrivacy = consentResult.needPrivacyPolicy;
    final showTerms = consentResult.needTermsOfService;

    debugPrint('🎯 Показываем селективный диалог:');
    debugPrint('   - Privacy Policy нужен: ${consentResult.needPrivacyPolicy}');
    debugPrint('   - Terms of Service нужен: ${consentResult.needTermsOfService}');
    debugPrint('   - Privacy Policy показать: $showPrivacy');
    debugPrint('   - Terms of Service показать: $showTerms');
    debugPrint('   - Устаревшие политики: $outdatedPolicies');

    final bool? agreementsAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Запрещаем закрытие свайпом/кнопкой назад
          child: UserAgreementsDialog(
            isRegistration: false,
            // ✅ СЕЛЕКТИВНЫЕ параметры - показываем только устаревшие документы
            showPrivacyPolicy: showPrivacy,
            showTermsOfService: showTerms,
            outdatedPolicies: outdatedPolicies,
            onAgreementsAccepted: () {
              debugPrint('✅ Селективные согласия приняты пользователем');
              debugPrint('📋 Обновлены политики: $outdatedPolicies');
              Navigator.of(context).pop(true);
            },
            onCancel: () {
              debugPrint('❌ Пользователь отказался от принятия селективных согласий');
              Navigator.of(context).pop(false);
            },
          ),
        );
      },
    );

    await _handlePolicyDialogResult(agreementsAccepted, outdatedPolicies);
  }

  /// ✅ НОВЫЙ: Fallback диалог в случае ошибки (показывает все политики)
  Future<void> _showFallbackPolicyDialog() async {
    if (!mounted) return;

    debugPrint('🚨 Показываем fallback диалог со всеми политиками');

    final bool? agreementsAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: UserAgreementsDialog(
            isRegistration: false,
            // ✅ Показываем все документы как fallback
            showPrivacyPolicy: true,
            showTermsOfService: true,
            outdatedPolicies: const ['privacy', 'terms'], // Все политики
            onAgreementsAccepted: () {
              debugPrint('✅ Fallback согласия приняты пользователем');
              Navigator.of(context).pop(true);
            },
            onCancel: () {
              debugPrint('❌ Пользователь отказался от принятия fallback согласий');
              Navigator.of(context).pop(false);
            },
          ),
        );
      },
    );

    await _handlePolicyDialogResult(agreementsAccepted, ['privacy', 'terms']);
  }

  /// ✅ НОВЫЙ: Обработка результата диалога принятия политик
  Future<void> _handlePolicyDialogResult(bool? accepted, List<String> updatedPolicies) async {
    if (accepted == true) {
      _consentsValid = true;
      debugPrint('✅ Согласия обновлены успешно: $updatedPolicies');

      // ✅ Обновляем кэшированный результат проверки
      await _updateConsentCheckCache();

      if (mounted) setState(() {}); // Обновляем UI
    } else {
      // ✅ МЯГКОЕ поведение при отклонении
      _consentsValid = false;

      if (mounted) {
        await _showPolicyReminderMessage(updatedPolicies);
      }
    }
  }

  /// ✅ НОВЫЙ: Обновление кэша результата проверки согласий
  Future<void> _updateConsentCheckCache() async {
    try {
      _lastConsentCheck = await _consentService.checkUserConsents();
    } catch (e) {
      debugPrint('❌ Ошибка обновления кэша согласий: $e');
    }
  }

  /// ✅ НОВЫЙ: Умное сообщение-напоминание в зависимости от устаревших политик
  Future<void> _showPolicyReminderMessage(List<String> rejectedPolicies) async {
    final localizations = AppLocalizations.of(context);

    // ✅ АДАПТИВНОЕ сообщение в зависимости от количества отклоненных политик
    String message;
    if (rejectedPolicies.length == 1) {
      final policyName = rejectedPolicies.first == 'privacy'
          ? (localizations.translate('privacy_policy'))
          : (localizations.translate('terms_of_service'));

      message = localizations.translate('single_policy_reminder')?.replaceFirst('{policy}', policyName) ??
          'Напоминание: обновилась $policyName. Вы можете принять новую версию в любое время в настройках.';
    } else {
      message = localizations.translate('multiple_policies_reminder') ??
          'Напоминание: обновились пользовательские соглашения. Вы можете принять новые версии в любое время в настройках.';
    }

    // ✅ ИСПРАВЛЕНО: Убрал ненужные ?. операторы - ScaffoldMessenger и context не могут быть null
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: localizations.translate('accept_now') ?? 'Принять сейчас',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // ✅ Повторно показываем диалог с теми же параметрами
            if (_lastConsentCheck != null) {
              _showSelectivePolicyDialog(_lastConsentCheck!);
            } else {
              _showFallbackPolicyDialog();
            }
          },
        ),
      ),
    );

    debugPrint('⚠️ Показано напоминание об отклоненных политиках: $rejectedPolicies');
  }

  /// ✅ УПРОЩЕННАЯ проверка возможности выполнения действия
  bool canPerformAction(String action) {
    return _consentsValid;
  }

  /// ✅ УЛУЧШЕННОЕ сообщение о блокировке действия с возможностью быстрого принятия
  void showActionBlockedMessage(String action) {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);

    // ✅ ИСПРАВЛЕНО: Убрал ненужные ?. операторы
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('action_blocked_consents_required') ??
              'Для выполнения действия необходимо принять согласия',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: localizations.translate('accept_consents') ?? 'Принять согласия',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // ✅ Показываем селективный диалог если есть кэш, иначе fallback
            if (_lastConsentCheck != null && !_lastConsentCheck!.allValid) {
              _showSelectivePolicyDialog(_lastConsentCheck!);
            } else {
              recheckConsents(); // Перепроверяем и показываем нужный диалог
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// ✅ БЕЗОПАСНОЕ выполнение действия
  Future<bool> safePerformAction(
      String action,
      Future<void> Function() actionCallback,
      ) async {
    if (!canPerformAction(action)) {
      showActionBlockedMessage(action);
      return false;
    }

    try {
      await actionCallback();
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при выполнении действия $action: $e');

      if (mounted) {
        final localizations = AppLocalizations.of(context);

        // ✅ ИСПРАВЛЕНО: Убрал ненужные ?. операторы
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('action_failed') ??
                  'Не удалось выполнить действие. Попробуйте еще раз.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return false;
    }
  }

  /// ✅ ВИДЖЕТ с проверкой согласий
  Widget buildRestrictedWidget({
    required String action,
    required Widget child,
    Widget? restrictedChild,
  }) {
    if (!canPerformAction(action)) {
      return restrictedChild ?? _buildRestrictedPlaceholder(action);
    }
    return child;
  }

  /// ✅ УЛУЧШЕННАЯ заглушка для заблокированного контента
  Widget _buildRestrictedPlaceholder(String action) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 48,
            color: Colors.orange[700],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('content_requires_consents') ??
                'Контент требует принятия согласий',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('accept_consents_to_unlock') ??
                'Примите пользовательские согласия для доступа к контенту',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // ✅ Умный показ диалога в зависимости от кэша
              if (_lastConsentCheck != null && !_lastConsentCheck!.allValid) {
                _showSelectivePolicyDialog(_lastConsentCheck!);
              } else {
                recheckConsents();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              localizations.translate('accept_consents') ?? 'Принять согласия',
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ГЕТТЕРЫ для проверки состояния

  /// Проверены ли согласия
  bool get consentsChecked => _consentsChecked;

  /// Валидны ли согласия
  bool get consentsValid => _consentsValid;

  /// ✅ НОВЫЙ: Получить последний результат проверки
  ConsentCheckResult? get lastConsentCheck => _lastConsentCheck;

  /// ✅ НОВЫЙ: Есть ли устаревшие политики
  bool get hasOutdatedPolicies => _lastConsentCheck?.hasChanges ?? false;

  /// ✅ НОВЫЙ: Список устаревших политик
  List<String> get outdatedPolicies => _lastConsentCheck?.outdatedPolicies ?? [];

  /// Может ли пользователь создавать контент
  bool get canCreateContent => _consentsValid;

  /// Может ли пользователь редактировать данные
  bool get canEditData => _consentsValid;

  /// Может ли пользователь использовать премиум функции
  bool get canUsePremiumFeatures => _consentsValid;

  /// ✅ УЛУЧШЕННАЯ принудительная перепроверка согласий
  Future<void> recheckConsents() async {
    debugPrint('🔄 Принудительная перепроверка согласий...');
    _consentsChecked = false;
    _consentsValid = false;
    _lastConsentCheck = null;
    await checkPolicyCompliance();
  }

  /// ✅ МЕТОД для сброса состояния согласий (например, при выходе)
  void resetConsentsState() {
    debugPrint('🔄 Сброс состояния согласий');
    _consentsChecked = false;
    _consentsValid = false;
    _lastConsentCheck = null;
  }

  /// ✅ НОВЫЙ: Быстрое принятие конкретной политики
  Future<bool> quickAcceptPolicy(String policyType) async {
    try {
      bool success = false;

      switch (policyType) {
        case 'privacy':
          success = await _consentService.updatePrivacyPolicyAcceptance(null);
          break;
        case 'terms':
          success = await _consentService.updateTermsOfServiceAcceptance(null);
          break;
        default:
          debugPrint('❌ Неизвестный тип политики: $policyType');
          return false;
      }

      if (success) {
        await _updateConsentCheckCache();
        _consentsValid = _lastConsentCheck?.allValid ?? false;
        if (mounted) setState(() {});
        debugPrint('✅ Политика $policyType принята быстрым методом');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Ошибка быстрого принятия политики $policyType: $e');
      return false;
    }
  }

  /// ✅ НОВЫЙ: Показать диалог только для конкретной политики
  Future<void> showSpecificPolicyDialog(String policyType) async {
    if (!mounted) return;

    final showPrivacy = policyType == 'privacy';
    final showTerms = policyType == 'terms';

    await _showSelectivePolicyDialog(ConsentCheckResult(
      allValid: false,
      needPrivacyPolicy: showPrivacy,
      needTermsOfService: showTerms,
      currentPrivacyVersion: '1.0.0',
      currentTermsVersion: '1.0.0',
    ));
  }
}