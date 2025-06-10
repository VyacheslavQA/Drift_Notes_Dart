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

          // Если документы уже приняты ранее, автоматически отмечаем их как принятые
          // (нужны для случая когда изменился только один документ)
          _privacyPolicyAccepted = !result.needPrivacyPolicy;
          _termsOfServiceAccepted = !result.needTermsOfService;
        });

        debugPrint('🔍 Результат проверки согласий: $result');
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

  /// Обрабатывает принятие соглашений (селективно)
  Future<void> _handleAcceptAgreements() async {
    if (_consentResult == null) return;

    // Проверяем что все НУЖНЫЕ документы приняты
    final needsPrivacy = _consentResult!.needPrivacyPolicy;
    final needsTerms = _consentResult!.needTermsOfService;

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

      // Используем селективное сохранение - только измененные документы
      if (needsPrivacy || needsTerms) {
        success = await _consentService.saveSelectiveConsents(
          privacyPolicyAccepted: needsPrivacy ? _privacyPolicyAccepted : null,
          termsOfServiceAccepted: needsTerms ? _termsOfServiceAccepted : null,
        );
      } else {
        // Если ничего не нужно принимать (не должно происходить), сохраняем все
        success = await _consentService.saveUserConsents(
          privacyPolicyAccepted: _privacyPolicyAccepted,
          termsOfServiceAccepted: _termsOfServiceAccepted,
        );
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

  /// Показывает сообщение об ошибке валидации (умное)
  void _showErrorMessage() {
    if (_consentResult == null) return;

    final localizations = AppLocalizations.of(context);
    String message;

    // Формируем сообщение в зависимости от того, что нужно принять
    if (_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      message = localizations.translate('terms_and_privacy_required') ??
          'Необходимо принять пользовательское соглашение и политику конфиденциальности';
    } else if (_consentResult!.needPrivacyPolicy) {
      message = 'Необходимо принять обновленную политику конфиденциальности';
    } else if (_consentResult!.needTermsOfService) {
      message = 'Необходимо принять обновленное пользовательское соглашение';
    } else {
      message = 'Необходимо принять соглашения для продолжения';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ошибка сохранения согласий. Попробуйте снова.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
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
      return localizations.translate('agreements_title') ?? 'Соглашения';
    }

    // Если только политика конфиденциальности
    if (_consentResult!.needPrivacyPolicy && !_consentResult!.needTermsOfService) {
      return 'Обновление политики конфиденциальности';
    }

    // Если только пользовательское соглашение
    if (!_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return 'Обновление пользовательского соглашения';
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
      return 'Обновились соглашения. Для продолжения работы необходимо принять новые версии.';
    }

    // Если только политика конфиденциальности
    if (_consentResult!.needPrivacyPolicy && !_consentResult!.needTermsOfService) {
      return 'Обновилась политика конфиденциальности. Для продолжения работы необходимо принять новую версию.';
    }

    // Если только пользовательское соглашение
    if (!_consentResult!.needPrivacyPolicy && _consentResult!.needTermsOfService) {
      return 'Обновилось пользовательское соглашение. Для продолжения работы необходимо принять новую версию.';
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
      return 'Принять все';
    }

    // Если только один документ
    if (_consentResult!.needPrivacyPolicy || _consentResult!.needTermsOfService) {
      return 'Принять обновление';
    }

    return localizations.translate('accept') ?? 'Принять';
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Проверка соглашений...'),
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
                          text: localizations.translate('i_agree_privacy_policy') ?? 'Я согласен с',
                          linkText: localizations.translate('privacy_policy_agreement') ?? 'Политикой конфиденциальности',
                          onLinkTap: _showPrivacyPolicy,
                          version: _consentResult?.currentPrivacyVersion,
                          isUpdated: _consentResult?.savedPrivacyVersion != null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Показываем пользовательское соглашение только если нужно
                      if (_consentResult?.needTermsOfService == true) ...[
                        _buildAgreementCheckbox(
                          value: _termsOfServiceAccepted,
                          onChanged: (value) => setState(() => _termsOfServiceAccepted = value ?? false),
                          text: localizations.translate('i_agree_terms') ?? 'Я согласен с',
                          linkText: localizations.translate('terms_of_service_agreement') ?? 'Пользовательским соглашением',
                          onLinkTap: _showTermsOfService,
                          version: _consentResult?.currentTermsVersion,
                          isUpdated: _consentResult?.savedTermsVersion != null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Информация о том, что осталось действующим (если есть)
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
                                  _buildValidDocumentsText(),
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

                          // Кнопка принятия (динамический текст)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _handleAcceptAgreements,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
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

  /// Формирует текст о том, какие документы остались действующими
  String _buildValidDocumentsText() {
    if (_consentResult == null) return '';

    List<String> validDocs = [];

    if (!_consentResult!.needPrivacyPolicy) {
      validDocs.add('Политика конфиденциальности v${_consentResult!.savedPrivacyVersion ?? 'текущая'} остается действующей');
    }

    if (!_consentResult!.needTermsOfService) {
      validDocs.add('Пользовательское соглашение v${_consentResult!.savedTermsVersion ?? 'текущее'} остается действующим');
    }

    return validDocs.join('. ');
  }

  /// Создает виджет checkbox с текстом и ссылкой (обновленный)
  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
    String? version,
    bool isUpdated = false,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

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
                            'ОБНОВЛЕНО',
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
                            'версия $version',
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