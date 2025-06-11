// Путь: lib/widgets/user_agreements_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../screens/help/privacy_policy_screen.dart';
import '../screens/help/terms_of_service_screen.dart';
import '../services/user_consent_service.dart';

/// Диалог соглашений с селективным показом измененных документов
class UserAgreementsDialog extends StatefulWidget {
  final VoidCallback onAgreementsAccepted;
  final VoidCallback? onCancel;

  const UserAgreementsDialog({
    super.key,
    required this.onAgreementsAccepted,
    this.onCancel,
  });

  @override
  State<UserAgreementsDialog> createState() => _UserAgreementsDialogState();
}

class _UserAgreementsDialogState extends State<UserAgreementsDialog> {
  bool _privacyPolicyAccepted = false;
  bool _termsOfServiceAccepted = false;
  bool _isProcessing = false;
  bool _isLoading = true;

  ConsentCheckResult? _consentResult;
  final UserConsentService _consentService = UserConsentService();

  @override
  void initState() {
    super.initState();
    _checkUserConsents();
  }

  /// Проверяет какие согласия нужно принять
  Future<void> _checkUserConsents() async {
    try {
      final result = await _consentService.checkUserConsents();

      if (mounted) {
        setState(() {
          _consentResult = result;
          _isLoading = false;

          // ИСПРАВЛЕНО: Правильная инициализация состояния
          // Документы, которые НЕ нужно принимать, автоматически считаются принятыми
          _privacyPolicyAccepted = !result.needPrivacyPolicy;
          _termsOfServiceAccepted = !result.needTermsOfService;
        });

        debugPrint('🔍 Результат проверки согласий: $result');
        debugPrint('🔧 Инициализация: privacy=$_privacyPolicyAccepted, terms=$_termsOfServiceAccepted');

        // ИСПРАВЛЕНО: Если все документы актуальны, автоматически закрываем диалог
        if (result.allValid) {
          debugPrint('✅ Все согласия актуальны - закрываем диалог');
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.of(context).pop();
              widget.onAgreementsAccepted();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Если ошибка - показываем все документы для безопасности
          _consentResult = ConsentCheckResult(
            allValid: false,
            needPrivacyPolicy: true,
            needTermsOfService: true,
            currentPrivacyVersion: '1.0.0',
            currentTermsVersion: '1.0.0',
          );
          _privacyPolicyAccepted = false;
          _termsOfServiceAccepted = false;
        });
      }
    }
  }

  /// Показывает политику конфиденциальности
  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  /// Показывает пользовательское соглашение
  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  /// ИСПРАВЛЕНО: Обрабатывает принятие соглашений (селективно)
  Future<void> _handleAcceptAgreements() async {
    if (_consentResult == null) return;

    // Проверяем что все НУЖНЫЕ документы приняты
    final needsPrivacy = _consentResult!.needPrivacyPolicy;
    final needsTerms = _consentResult!.needTermsOfService;

    debugPrint('🔍 Проверка перед сохранением:');
    debugPrint('   needsPrivacy: $needsPrivacy, accepted: $_privacyPolicyAccepted');
    debugPrint('   needsTerms: $needsTerms, accepted: $_termsOfServiceAccepted');

    if ((needsPrivacy && !_privacyPolicyAccepted) ||
        (needsTerms && !_termsOfServiceAccepted)) {
      _showErrorMessage();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      bool success = false;

      // ИСПРАВЛЕНО: Правильная логика селективного сохранения
      if (needsPrivacy || needsTerms) {
        // Сохраняем только те документы, которые пользователь ДЕЙСТВИТЕЛЬНО принимал
        success = await _consentService.saveSelectiveConsents(
          privacyPolicyAccepted: needsPrivacy ? _privacyPolicyAccepted : null,
          termsOfServiceAccepted: needsTerms ? _termsOfServiceAccepted : null,
        );

        debugPrint('💾 Селективное сохранение: Privacy=${needsPrivacy ? _privacyPolicyAccepted : 'skip'}, Terms=${needsTerms ? _termsOfServiceAccepted : 'skip'}');
      } else {
        // Если ничего не нужно принимать (не должно происходить в этом диалоге)
        debugPrint('⚠️ Неожиданная ситуация: нечего сохранять');
        success = true;
      }

      if (success && mounted) {
        debugPrint('✅ Согласия успешно сохранены селективно');
        // Закрываем диалог и вызываем коллбэк
        Navigator.of(context).pop();
        widget.onAgreementsAccepted();
      } else if (mounted) {
        _showSaveErrorMessage();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при принятии соглашений: $e');
      if (mounted) {
        _showSaveErrorMessage();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// ИСПРАВЛЕНО: Показывает сообщение об ошибке валидации (умное)
  void _showErrorMessage() {
    if (_consentResult == null) return;

    final localizations = AppLocalizations.of(context);
    String message;

    // Формируем сообщение в зависимости от того, что РЕАЛЬНО нужно принять
    List<String> needed = [];

    if (_consentResult!.needPrivacyPolicy && !_privacyPolicyAccepted) {
      needed.add(localizations.translate('privacy_policy') ?? 'политику конфиденциальности');
    }

    if (_consentResult!.needTermsOfService && !_termsOfServiceAccepted) {
      needed.add(localizations.translate('terms_of_service') ?? 'пользовательское соглашение');
    }

    if (needed.isEmpty) {
      message = localizations.translate('agreements_required') ?? 'Необходимо принять соглашения для продолжения';
    } else if (needed.length == 1) {
      message = '${localizations.translate('need_to_accept') ?? 'Необходимо принять'} ${needed[0]}';
    } else {
      message = '${localizations.translate('need_to_accept') ?? 'Необходимо принять'} ${needed.join(' и ')}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Показывает сообщение об ошибке сохранения
  void _showSaveErrorMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('error_saving_agreements') ?? 'Ошибка сохранения согласий. Попробуйте снова.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Обрабатывает отмену
  void _handleCancel() {
    Navigator.of(context).pop();
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  /// Получает динамический заголовок в зависимости от контекста
  String _getDialogTitle(AppLocalizations localizations) {
    if (_consentResult == null) {
      return localizations.translate('agreements_title') ?? 'Соглашения';
    }

    // Если нужно принять оба документа - общий заголовок
    if (_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return localizations.translate('agreements_update_title') ?? 'Обновление соглашений';
    }

    // Если только политика конфиденциальности
    if (_consentResult!.needPrivacyPolicy && !_consentResult!.needTermsOfService) {
      return localizations.translate('privacy_policy_update_title') ?? 'Обновление политики конфиденциальности';
    }

    // Если только пользовательское соглашение
    if (!_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return localizations.translate('terms_update_title') ?? 'Обновление пользовательского соглашения';
    }

    return localizations.translate('agreements_title') ?? 'Соглашения';
  }

  /// Получает динамическое описание в зависимости от контекста
  String _getDialogDescription(AppLocalizations localizations) {
    if (_consentResult == null) {
      return localizations.translate('agreements_description') ??
          'Для продолжения работы с приложением необходимо принять соглашения';
    }

    // Если нужно принять оба документа
    if (_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return localizations.translate('both_agreements_updated') ??
          'Обновились соглашения. Для продолжения работы необходимо принять новые версии.';
    }

    // Если только политика конфиденциальности
    if (_consentResult!.needPrivacyPolicy && !_consentResult!.needTermsOfService) {
      return localizations.translate('privacy_policy_updated') ??
          'Обновилась политика конфиденциальности. Для продолжения работы необходимо принять новую версию.';
    }

    // Если только пользовательское соглашение
    if (!_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return localizations.translate('terms_updated') ??
          'Обновилось пользовательское соглашение. Для продолжения работы необходимо принять новую версию.';
    }

    return localizations.translate('agreements_description') ??
        'Для продолжения работы с приложением необходимо принять соглашения';
  }

  /// Получает текст кнопки в зависимости от контекста
  String _getAcceptButtonText(AppLocalizations localizations) {
    if (_consentResult == null) {
      return localizations.translate('accept') ?? 'Принять';
    }

    // Если нужно принять оба документа
    if (_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return localizations.translate('accept_all_updates') ?? 'Принять все обновления';
    }

    // Если только один документ
    if (_consentResult!.needPrivacyPolicy || _consentResult!.needTermsOfService) {
      return localizations.translate('accept_update') ?? 'Принять обновление';
    }

    return localizations.translate('accept') ?? 'Принять';
  }

  /// ИСПРАВЛЕНО: Проверяет можно ли активировать кнопку "Принять"
  bool _canAccept() {
    if (_consentResult == null) return false;

    // Кнопка активна если все НУЖНЫЕ документы приняты
    final privacyOk = !_consentResult!.needPrivacyPolicy || _privacyPolicyAccepted;
    final termsOk = !_consentResult!.needTermsOfService || _termsOfServiceAccepted;

    return privacyOk && termsOk;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final screenSize = MediaQuery.of(context).size;

    // Показываем загрузку пока проверяем согласия
    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: AppConstants.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.9,
              maxHeight: 200,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(localizations.translate('checking_agreements') ?? 'Проверка соглашений...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppConstants.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
            maxHeight: screenSize.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок (динамический)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _consentResult?.hasChanges == true ? Icons.update : Icons.security,
                      color: AppConstants.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getDialogTitle(localizations),
                      style: TextStyle(
                        fontSize: 22 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDialogDescription(localizations),
                      style: TextStyle(
                        fontSize: 14 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                        color: AppConstants.textColor.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Основное содержимое (селективное)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Показываем политику конфиденциальности только если нужна
                      if (_consentResult?.needPrivacyPolicy == true) ...[
                        _buildAgreementCheckbox(
                          value: _privacyPolicyAccepted,
                          onChanged: (value) => setState(() => _privacyPolicyAccepted = value ?? false),
                          text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                          linkText: localizations.translate('privacy_policy') ?? 'Политикой конфиденциальности',
                          onLinkTap: _showPrivacyPolicy,
                          version: _consentResult?.currentPrivacyVersion,
                          isUpdated: _consentResult?.savedPrivacyVersion != null,
                          oldVersion: _consentResult?.savedPrivacyVersion,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Показываем пользовательское соглашение только если нужно
                      if (_consentResult?.needTermsOfService == true) ...[
                        _buildAgreementCheckbox(
                          value: _termsOfServiceAccepted,
                          onChanged: (value) => setState(() => _termsOfServiceAccepted = value ?? false),
                          text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                          linkText: localizations.translate('terms_of_service') ?? 'Пользовательским соглашением',
                          onLinkTap: _showTermsOfService,
                          version: _consentResult?.currentTermsVersion,
                          isUpdated: _consentResult?.savedTermsVersion != null,
                          oldVersion: _consentResult?.savedTermsVersion,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ИСПРАВЛЕНО: Информация о том, что осталось действующим
                      if (_consentResult != null &&
                          (!_consentResult!.needPrivacyPolicy || !_consentResult!.needTermsOfService)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _buildValidDocumentsText(localizations),
                                  style: TextStyle(
                                    fontSize: 12 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 8),

                      // Кнопки
                      Row(
                        children: [
                          // Кнопка отмены
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _handleCancel,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppConstants.textColor.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                localizations.translate('cancel') ?? 'Отмена',
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // ИСПРАВЛЕНО: Кнопка принятия с правильной логикой активации
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isProcessing || !_canAccept()) ? null : _handleAcceptAgreements,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Text(
                                _getAcceptButtonText(localizations),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ИСПРАВЛЕНО: Формирует текст о том, какие документы остались действующими
  String _buildValidDocumentsText(AppLocalizations localizations) {
    if (_consentResult == null) return '';

    List<String> validDocs = [];

    if (!_consentResult!.needPrivacyPolicy) {
      final version = _consentResult!.savedPrivacyVersion ?? _consentResult!.currentPrivacyVersion;
      validDocs.add(localizations.translate('privacy_policy_remains_valid')?.replaceAll('{version}', version) ??
          'Политика конфиденциальности v$version остается действующей');
    }

    if (!_consentResult!.needTermsOfService) {
      final version = _consentResult!.savedTermsVersion ?? _consentResult!.currentTermsVersion;
      validDocs.add(localizations.translate('terms_remains_valid')?.replaceAll('{version}', version) ??
          'Пользовательское соглашение v$version остается действующим');
    }

    return validDocs.join('. ');
  }

  /// ИСПРАВЛЕНО: Создает виджет checkbox с текстом и ссылкой (обновленный)
  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
    String? version,
    String? oldVersion,
    bool isUpdated = false,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isUpdated ? Colors.blue.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: isUpdated ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppConstants.primaryColor,
              checkColor: Colors.white,
              side: BorderSide(
                color: AppConstants.textColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Текст с ссылкой и версией
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: text),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: linkText,
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                        ),
                      ],
                    ),
                  ),

                  // Показываем информацию о версии и обновлении
                  if (version != null || isUpdated) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isUpdated) ...[
                          Icon(Icons.fiber_new, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            localizations.translate('updated') ?? 'ОБНОВЛЕНО',
                            style: TextStyle(
                              fontSize: 11 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (version != null) ...[
                          Text(
                            isUpdated && oldVersion != null
                                ? 'v$oldVersion → v$version'
                                : '${localizations.translate('version') ?? 'версия'} $version',
                            style: TextStyle(
                              fontSize: 11 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                              color: AppConstants.textColor.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}