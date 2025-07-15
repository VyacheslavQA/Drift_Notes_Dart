// Путь: lib/mixins/policy_enforcement_mixin.dart

import 'package:flutter/material.dart';
import '../services/user_consent_service.dart';
import '../services/firebase/firebase_service.dart';
import '../widgets/user_agreements_dialog.dart';
import '../localization/app_localizations.dart';
import '../constants/app_constants.dart';

/// ✅ УПРОЩЕННЫЙ миксин для проверки согласий пользователя
/// Убрана сложная система ограничений - только простая проверка: согласия приняты ДА/НЕТ
mixin PolicyEnforcementMixin<T extends StatefulWidget> on State<T> {
  final UserConsentService _consentService = UserConsentService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _consentsChecked = false;
  bool _consentsValid = false;

  /// ✅ УПРОЩЕННАЯ проверка согласий при инициализации
  Future<void> checkPolicyCompliance() async {
    if (_consentsChecked) return; // Избегаем повторных проверок

    try {
      debugPrint('📋 Проверяем согласия пользователя...');

      final consentResult = await _consentService.checkUserConsents();
      _consentsChecked = true;
      _consentsValid = consentResult.allValid;

      if (!consentResult.allValid) {
        debugPrint('🚫 Согласия не приняты или устарели - показываем диалог');
        await _showMandatoryPolicyDialog();
      } else {
        debugPrint('✅ Все согласия актуальны');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке согласий: $e');
      _consentsChecked = true;
      _consentsValid = false;
      // В случае ошибки показываем диалог для безопасности
      await _showMandatoryPolicyDialog();
    }
  }

  /// ✅ ИСПРАВЛЕН: Показывает диалог принятия согласий с правильными параметрами
  Future<void> _showMandatoryPolicyDialog() async {
    if (!mounted) return;

    final bool? agreementsAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Запрещаем закрытие свайпом/кнопкой назад
          child: UserAgreementsDialog(
            isRegistration: false, // ✅ ИСПРАВЛЕНО: добавлен обязательный параметр
            onAgreementsAccepted: () {
              debugPrint('✅ Согласия приняты пользователем');
              Navigator.of(context).pop(true);
            },
            onCancel: () {
              debugPrint('❌ Пользователь отказался от принятия согласий');
              Navigator.of(context).pop(false);
            },
          ),
        );
      },
    );

    // ✅ УПРОЩЕННАЯ логика: принял - продолжаем, отказался - выход
    if (agreementsAccepted == true) {
      _consentsValid = true;
      if (mounted) setState(() {}); // Обновляем UI
    } else {
      // Если пользователь отказался - выходим из аккаунта
      debugPrint('🚪 Выход из аккаунта из-за отказа от согласий');
      await _firebaseService.signOut();

      if (mounted) {
        // Показываем сообщение и возвращаемся на экран входа
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('consents_required') ??
                  'Для использования приложения необходимо принять согласия',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Навигация на экран входа будет обработана автоматически
        // через FirebaseAuth.authStateChanges в main.dart
      }
    }
  }

  /// ✅ УПРОЩЕННАЯ проверка возможности выполнения действия
  /// Теперь проверяется только: приняты ли согласия
  bool canPerformAction(String action) {
    return _consentsValid;
  }

  /// ✅ УПРОЩЕННОЕ сообщение о блокировке действия
  void showActionBlockedMessage(String action) {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localizations?.translate('action_blocked_consents_required') ??
              'Для выполнения действия необходимо принять согласия',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: localizations?.translate('accept_consents') ??
              'Принять согласия',
          textColor: Colors.white,
          onPressed: () => _showMandatoryPolicyDialog(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// ✅ УПРОЩЕННОЕ безопасное выполнение действия
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('action_failed') ??
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

  /// ✅ УПРОЩЕННЫЙ виджет с проверкой согласий
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

  /// ✅ УПРОЩЕННАЯ заглушка для заблокированного контента
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
            localizations?.translate('content_requires_consents') ??
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
            localizations?.translate('accept_consents_to_unlock') ??
                'Примите пользовательские согласия для доступа к контенту',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showMandatoryPolicyDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              localizations?.translate('accept_consents') ??
                  'Принять согласия',
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ УПРОЩЕННЫЕ геттеры для проверки состояния

  /// Проверены ли согласия
  bool get consentsChecked => _consentsChecked;

  /// Валидны ли согласия
  bool get consentsValid => _consentsValid;

  /// Может ли пользователь создавать контент
  bool get canCreateContent => _consentsValid;

  /// Может ли пользователь редактировать данные
  bool get canEditData => _consentsValid;

  /// Может ли пользователь использовать премиум функции
  bool get canUsePremiumFeatures => _consentsValid;

  /// ✅ МЕТОД для принудительной перепроверки согласий
  Future<void> recheckConsents() async {
    _consentsChecked = false;
    _consentsValid = false;
    await checkPolicyCompliance();
  }

  /// ✅ МЕТОД для сброса состояния согласий (например, при выходе)
  void resetConsentsState() {
    _consentsChecked = false;
    _consentsValid = false;
  }
}