// Путь: lib/widgets/user_agreements_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../screens/help/privacy_policy_screen.dart';
import '../screens/help/terms_of_service_screen.dart';
import '../services/user_consent_service.dart';

/// Диалог соглашений для новых пользователей
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

  final UserConsentService _consentService = UserConsentService();

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

  /// Обрабатывает принятие соглашений
  Future<void> _handleAcceptAgreements() async {
    if (!_privacyPolicyAccepted || !_termsOfServiceAccepted) {
      _showErrorMessage();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Сохраняем согласия
      final success = await _consentService.saveUserConsents(
        privacyPolicyAccepted: _privacyPolicyAccepted,
        termsOfServiceAccepted: _termsOfServiceAccepted,
      );

      if (success && mounted) {
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

  /// Показывает сообщение об ошибке валидации
  void _showErrorMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('terms_and_privacy_required')),
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        // Предотвращаем закрытие диалога по back button
        return false;
      },
      child: Dialog(
        backgroundColor: AppConstants.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
            maxHeight: screenSize.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
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
                      Icons.security,
                      color: AppConstants.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.translate('agreements_title') ?? 'Соглашения',
                      style: TextStyle(
                        fontSize: 22 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('agreements_description') ??
                          'Для продолжения работы с приложением необходимо принять соглашения',
                      style: TextStyle(
                        fontSize: 14 * (textScaler.scale(1.0) > 1.2 ? 1.2 / textScaler.scale(1.0) : 1),
                        color: AppConstants.textColor.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Основное содержимое
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Галочка для политики конфиденциальности
                      _buildAgreementCheckbox(
                        value: _privacyPolicyAccepted,
                        onChanged: (value) => setState(() => _privacyPolicyAccepted = value ?? false),
                        text: localizations.translate('i_agree_privacy_policy') ?? 'Я согласен с',
                        linkText: localizations.translate('privacy_policy_agreement') ?? 'Политикой конфиденциальности',
                        onLinkTap: _showPrivacyPolicy,
                      ),

                      const SizedBox(height: 16),

                      // Галочка для пользовательского соглашения
                      _buildAgreementCheckbox(
                        value: _termsOfServiceAccepted,
                        onChanged: (value) => setState(() => _termsOfServiceAccepted = value ?? false),
                        text: localizations.translate('i_agree_terms') ?? 'Я согласен с',
                        linkText: localizations.translate('terms_of_service_agreement') ?? 'Пользовательским соглашением',
                        onLinkTap: _showTermsOfService,
                      ),

                      const SizedBox(height: 24),

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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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

                          // Кнопка принятия
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _handleAcceptAgreements,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
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

  /// Создает виджет checkbox с текстом и ссылкой
  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Row(
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
    );
  }
}