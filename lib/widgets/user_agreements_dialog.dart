// Путь: lib/widgets/user_agreements_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../screens/help/privacy_policy_screen.dart';
import '../screens/help/terms_of_service_screen.dart';
import '../services/user_consent_service.dart';

/// ✅ СЕЛЕКТИВНЫЙ диалог соглашений - показывает только устаревшие документы
class UserAgreementsDialog extends StatefulWidget {
  final VoidCallback onAgreementsAccepted;
  final VoidCallback? onCancel;
  final bool isRegistration; // Контекст использования

  // ✅ НОВЫЕ параметры для селективного показа
  final bool showPrivacyPolicy;
  final bool showTermsOfService;

  // ✅ НОВЫЕ параметры для передачи информации об устаревших документах
  final List<String> outdatedPolicies; // ['privacy', 'terms'] или их подмножество

  const UserAgreementsDialog({
    super.key,
    required this.onAgreementsAccepted,
    this.onCancel,
    this.isRegistration = false,
    // ✅ Параметры селективности
    this.showPrivacyPolicy = true,
    this.showTermsOfService = true,
    this.outdatedPolicies = const ['privacy', 'terms'], // По умолчанию все
  });

  @override
  State<UserAgreementsDialog> createState() => _UserAgreementsDialogState();
}

class _UserAgreementsDialogState extends State<UserAgreementsDialog> {
  bool _privacyPolicyAccepted = false;
  bool _termsOfServiceAccepted = false;
  bool _isProcessing = false;

  final UserConsentService _consentService = UserConsentService();

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 Показываем селективный диалог согласий');
    debugPrint('📋 Показать Privacy Policy: ${widget.showPrivacyPolicy}');
    debugPrint('📋 Показать Terms of Service: ${widget.showTermsOfService}');
    debugPrint('📋 Устаревшие политики: ${widget.outdatedPolicies}');

    // ✅ ИСПРАВЛЕНО: Автоматически принимаем скрытые документы
    if (!widget.showPrivacyPolicy) {
      _privacyPolicyAccepted = true;
      debugPrint('🔒 Privacy Policy скрыт - автоматически принят');
    }
    if (!widget.showTermsOfService) {
      _termsOfServiceAccepted = true;
      debugPrint('🔒 Terms of Service скрыт - автоматически принят');
    }

    debugPrint('📊 Состояние после инициализации:');
    debugPrint('   - _privacyPolicyAccepted: $_privacyPolicyAccepted');
    debugPrint('   - _termsOfServiceAccepted: $_termsOfServiceAccepted');
  }

  /// Показывает политику конфиденциальности
  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  /// Показывает пользовательское соглашение
  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  /// ✅ СЕЛЕКТИВНОЕ принятие - обновляем только показанные документы
  Future<void> _handleAcceptAgreements() async {
    // ✅ Проверяем что показанные документы приняты
    if ((widget.showPrivacyPolicy && !_privacyPolicyAccepted) ||
        (widget.showTermsOfService && !_termsOfServiceAccepted)) {
      _showErrorMessage();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ✅ СЕЛЕКТИВНОЕ сохранение - передаем только те документы, которые нужно обновить
      final success = await _consentService.saveSelectiveConsents(
        privacyPolicyAccepted: widget.showPrivacyPolicy ? _privacyPolicyAccepted : null,
        termsOfServiceAccepted: widget.showTermsOfService ? _termsOfServiceAccepted : null,
        outdatedPolicies: widget.outdatedPolicies, // ✅ Передаем контекст устаревших политик
      );

      if (success && mounted) {
        debugPrint('✅ Селективные согласия успешно сохранены');
        debugPrint('📋 Обновлены политики: ${widget.outdatedPolicies}');
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

  /// Отказ от принятия соглашений
  Future<void> _handleDeclineAgreements() async {
    debugPrint('❌ Пользователь отклонил соглашения');

    if (mounted) {
      Navigator.of(context).pop();
      if (widget.onCancel != null) {
        widget.onCancel!();
      }
    }
  }

  /// ✅ АДАПТИВНОЕ сообщение об ошибке
  void _showErrorMessage() {
    final localizations = AppLocalizations.of(context);

    // Определяем какие документы нужно принять
    List<String> requiredDocs = [];
    if (widget.showPrivacyPolicy && !_privacyPolicyAccepted) {
      requiredDocs.add(localizations.translate('privacy_policy') ?? 'Политику конфиденциальности');
    }
    if (widget.showTermsOfService && !_termsOfServiceAccepted) {
      requiredDocs.add(localizations.translate('terms_of_service') ?? 'Пользовательское соглашение');
    }

    String message;
    if (requiredDocs.length == 1) {
      message = '${localizations.translate('need_to_accept') ?? 'Необходимо принять'} ${requiredDocs.first}';
    } else {
      message = localizations.translate('agreements_required') ?? 'Необходимо принять все соглашения для продолжения';
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
        content: Text(
          localizations.translate('error_saving_agreements') ??
              'Ошибка сохранения согласий. Попробуйте снова.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ АДАПТИВНЫЙ заголовок в зависимости от контекста
  String _getDialogTitle(AppLocalizations localizations) {
    if (widget.isRegistration) {
      return localizations.translate('accept_agreements_title') ?? 'Принятие соглашений';
    } else {
      // Для обновлений показываем более конкретную информацию
      if (widget.outdatedPolicies.length == 1) {
        String policyName = widget.outdatedPolicies.first == 'privacy'
            ? (localizations.translate('privacy_policy') ?? 'Политика конфиденциальности')
            : (localizations.translate('terms_of_service') ?? 'Пользовательское соглашение');
        return '${localizations.translate('update_single_policy') ?? 'Обновление'} $policyName';
      } else {
        return localizations.translate('agreements_update_title') ?? 'Обновление соглашений';
      }
    }
  }

  /// ✅ АДАПТИВНОЕ описание в зависимости от контекста
  String _getDialogDescription(AppLocalizations localizations) {
    if (widget.isRegistration) {
      return localizations.translate('accept_agreements_description') ??
          'Для использования приложения необходимо принять соглашения';
    } else {
      // Для обновлений показываем что именно обновилось
      if (widget.outdatedPolicies.length == 1) {
        String policyName = widget.outdatedPolicies.first == 'privacy'
            ? (localizations.translate('privacy_policy') ?? 'Политика конфиденциальности')
            : (localizations.translate('terms_of_service') ?? 'Пользовательское соглашение');
        return '${localizations.translate('single_policy_updated') ?? 'Обновилась'} $policyName. ${localizations.translate('please_review_accept') ?? 'Пожалуйста, ознакомьтесь и примите новую версию.'}';
      } else {
        return localizations.translate('agreements_update_description') ??
            'Обновились соглашения. Для продолжения работы необходимо принять новые версии.';
      }
    }
  }

  /// ✅ СЕЛЕКТИВНАЯ проверка - только показанные документы должны быть приняты
  bool _canAccept() {
    bool privacyOk = !widget.showPrivacyPolicy || _privacyPolicyAccepted;
    bool termsOk = !widget.showTermsOfService || _termsOfServiceAccepted;
    return privacyOk && termsOk;
  }

  /// ✅ ВСПОМОГАТЕЛЬНЫЙ метод - проверяет есть ли документы для показа
  bool _hasDocumentsToShow() {
    final hasDocuments = widget.showPrivacyPolicy || widget.showTermsOfService;
    debugPrint('🔍 _hasDocumentsToShow(): $hasDocuments');
    debugPrint('   - showPrivacyPolicy: ${widget.showPrivacyPolicy}');
    debugPrint('   - showTermsOfService: ${widget.showTermsOfService}');
    return hasDocuments;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final screenSize = MediaQuery.of(context).size;

    // ✅ ЗАЩИТА: Если нет документов для показа, не показываем диалог
    if (!_hasDocumentsToShow()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onAgreementsAccepted();
        }
      });
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async => false, // Нельзя закрыть без принятия
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
              // ✅ АДАПТИВНЫЙ заголовок
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
                      widget.isRegistration ? Icons.security : Icons.update,
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

              // ✅ СЕЛЕКТИВНОЕ содержимое - показываем только нужные документы
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ УСЛОВНОЕ отображение политики конфиденциальности
                      if (widget.showPrivacyPolicy) ...[
                        _buildSelectiveAgreementCheckbox(
                          value: _privacyPolicyAccepted,
                          onChanged: (value) => setState(() => _privacyPolicyAccepted = value ?? false),
                          text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                          linkText: localizations.translate('privacy_policy') ?? 'Политикой конфиденциальности',
                          onLinkTap: _showPrivacyPolicy,
                          isUpdated: widget.outdatedPolicies.contains('privacy'),
                        ),
                        if (widget.showTermsOfService) const SizedBox(height: 16),
                      ],

                      // ✅ УСЛОВНОЕ отображение пользовательского соглашения
                      if (widget.showTermsOfService) ...[
                        _buildSelectiveAgreementCheckbox(
                          value: _termsOfServiceAccepted,
                          onChanged: (value) => setState(() => _termsOfServiceAccepted = value ?? false),
                          text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                          linkText: localizations.translate('terms_of_service') ?? 'Пользовательским соглашением',
                          onLinkTap: _showTermsOfService,
                          isUpdated: widget.outdatedPolicies.contains('terms'),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ✅ АДАПТИВНЫЕ кнопки
                      Row(
                        children: [
                          // Кнопка отмены
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : _handleDeclineAgreements,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.withOpacity(0.7)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                widget.isRegistration
                                    ? (localizations.translate('exit_app') ?? 'Выйти из приложения')
                                    : (localizations.translate('decline') ?? 'Отклонить'),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Кнопка принятия
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isProcessing || !_canAccept()) ? null : _handleAcceptAgreements,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                                localizations.translate('accept') ?? 'Принять',
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

  /// ✅ СЕЛЕКТИВНЫЙ виджет checkbox с индикацией обновления
  Widget _buildSelectiveAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
    required bool isUpdated, // Новый параметр - указывает что документ обновлен
  }) {
    final textScaler = MediaQuery.of(context).textScaler;
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      // ✅ Выделяем обновленные документы
      decoration: isUpdated && !widget.isRegistration
          ? BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Индикатор обновления
          if (isUpdated && !widget.isRegistration)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.new_releases,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    localizations.translate('document_updated') ?? 'Документ обновлен',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 12 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Основной checkbox с текстом
          Row(
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

              // Текст с ссылкой
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}