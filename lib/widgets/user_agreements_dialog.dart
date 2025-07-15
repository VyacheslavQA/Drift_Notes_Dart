// Путь: lib/widgets/user_agreements_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../screens/help/privacy_policy_screen.dart';
import '../screens/help/terms_of_service_screen.dart';
import '../services/user_consent_service.dart';

/// ✅ УПРОЩЕННЫЙ диалог соглашений без сложной селективной логики
class UserAgreementsDialog extends StatefulWidget {
  final VoidCallback onAgreementsAccepted;
  final VoidCallback? onCancel;
  final bool isRegistration; // Новый параметр для контекста

  const UserAgreementsDialog({
    super.key,
    required this.onAgreementsAccepted,
    this.onCancel,
    this.isRegistration = false, // По умолчанию - обновление политик
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
    // ✅ УПРОЩЕНО: Никаких сложных проверок - всегда показываем оба документа
    debugPrint('🔍 Показываем упрощенный диалог согласий');
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

  /// ✅ УПРОЩЕНО: Простое принятие всех соглашений
  Future<void> _handleAcceptAgreements() async {
    // Проверяем что оба документа приняты
    if (!_privacyPolicyAccepted || !_termsOfServiceAccepted) {
      _showErrorMessage();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ✅ УПРОЩЕНО: Всегда сохраняем оба документа (не селективно)
      final success = await _consentService.saveSelectiveConsents(
        privacyPolicyAccepted: _privacyPolicyAccepted,
        termsOfServiceAccepted: _termsOfServiceAccepted,
      );

      if (success && mounted) {
        debugPrint('✅ Согласия успешно сохранены');
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

  /// ✅ УПРОЩЕНО: Простой отказ без записи в систему
  Future<void> _handleDeclineAgreements() async {
    // ✅ УПРОЩЕНО: Убрана запись отказа с планированием удаления
    // Просто закрываем диалог и вызываем коллбэк
    debugPrint('❌ Пользователь отклонил соглашения');

    if (mounted) {
      Navigator.of(context).pop();
      if (widget.onCancel != null) {
        widget.onCancel!();
      }
    }
  }

  /// ✅ УПРОЩЕНО: Простое сообщение об ошибке
  void _showErrorMessage() {
    final localizations = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations.translate('agreements_required') ??
              'Необходимо принять все соглашения для продолжения',
        ),
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

  /// ✅ УПРОЩЕНО: Простой статический заголовок
  String _getDialogTitle(AppLocalizations localizations) {
    if (widget.isRegistration) {
      return localizations.translate('accept_agreements_title') ?? 'Принятие соглашений';
    } else {
      return localizations.translate('agreements_update_title') ?? 'Обновление соглашений';
    }
  }

  /// ✅ УПРОЩЕНО: Простое статическое описание
  String _getDialogDescription(AppLocalizations localizations) {
    if (widget.isRegistration) {
      return localizations.translate('accept_agreements_description') ??
          'Для использования приложения необходимо принять соглашения';
    } else {
      return localizations.translate('agreements_update_description') ??
          'Обновились соглашения. Для продолжения работы необходимо принять новые версии.';
    }
  }

  /// ✅ УПРОЩЕНО: Простая проверка - оба документа должны быть приняты
  bool _canAccept() {
    return _privacyPolicyAccepted && _termsOfServiceAccepted;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final screenSize = MediaQuery.of(context).size;

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
              // ✅ УПРОЩЕННЫЙ заголовок
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

              // ✅ УПРОЩЕННОЕ содержимое - всегда показываем оба документа
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Политика конфиденциальности (всегда показываем)
                      _buildSimpleAgreementCheckbox(
                        value: _privacyPolicyAccepted,
                        onChanged: (value) => setState(() => _privacyPolicyAccepted = value ?? false),
                        text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                        linkText: localizations.translate('privacy_policy') ?? 'Политикой конфиденциальности',
                        onLinkTap: _showPrivacyPolicy,
                      ),

                      const SizedBox(height: 16),

                      // Пользовательское соглашение (всегда показываем)
                      _buildSimpleAgreementCheckbox(
                        value: _termsOfServiceAccepted,
                        onChanged: (value) => setState(() => _termsOfServiceAccepted = value ?? false),
                        text: localizations.translate('i_agree_to') ?? 'Я согласен с',
                        linkText: localizations.translate('terms_of_service') ?? 'Пользовательским соглашением',
                        onLinkTap: _showTermsOfService,
                      ),

                      const SizedBox(height: 24),

                      // ✅ УПРОЩЕННЫЕ кнопки
                      Row(
                        children: [
                          // Кнопка отмены (простая)
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

                          // Кнопка принятия (простая)
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

  /// ✅ УПРОЩЕННЫЙ виджет checkbox без сложной логики версий
  Widget _buildSimpleAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    return Container(
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

          // Простой текст с ссылкой
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
    );
  }
}