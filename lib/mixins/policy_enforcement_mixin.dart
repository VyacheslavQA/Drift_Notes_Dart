// Путь: lib/mixins/policy_enforcement_mixin.dart

import 'package:flutter/material.dart';
import '../services/user_consent_service.dart';
import '../widgets/user_agreements_dialog.dart';
import '../localization/app_localizations.dart';
import '../constants/app_constants.dart';

/// Миксин для проверки политики конфиденциальности и применения ограничений
mixin PolicyEnforcementMixin<T extends StatefulWidget> on State<T> {
  final UserConsentService _consentService = UserConsentService();
  ConsentRestrictionResult? _currentRestrictions;

  /// Проверяет политику конфиденциальности при инициализации
  Future<void> checkPolicyCompliance() async {
    try {
      final consentResult = await _consentService.checkUserConsents();

      if (!consentResult.allValid) {
        debugPrint('🚫 Политика не принята - показываем принудительный диалог');
        await _showMandatoryPolicyDialog();
      }

      // Получаем текущие ограничения
      _currentRestrictions = await _consentService.getConsentRestrictions();

      if (_currentRestrictions!.hasRestrictions) {
        debugPrint('⚠️ Действуют ограничения: ${_currentRestrictions!.level}');
        _showRestrictionBanner();
      }
    } catch (e) {
      debugPrint('❌ Ошибка при проверке политики: $e');
    }
  }

  /// Показывает принудительный диалог принятия политики
  Future<void> _showMandatoryPolicyDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Запрещаем закрытие диалога
          child: UserAgreementsDialog(
            onAgreementsAccepted: () {
              debugPrint('✅ Политика принята пользователем');
              _refreshRestrictions();
            },
            onCancel: () async {
              debugPrint('❌ Пользователь отказался от принятия политики');
              await _consentService.recordPolicyRejection();
              _refreshRestrictions();
            },
          ),
        );
      },
    );
  }

  /// Обновляет ограничения после изменений
  Future<void> _refreshRestrictions() async {
    if (!mounted) return;

    _currentRestrictions = await _consentService.getConsentRestrictions();

    if (_currentRestrictions!.hasRestrictions) {
      _showRestrictionBanner();
    }

    setState(() {}); // Обновляем UI
  }

  /// Показывает баннер с информацией об ограничениях
  void _showRestrictionBanner() {
    if (!mounted || _currentRestrictions == null) return;

    final localizations = AppLocalizations.of(context);
    final restrictions = _currentRestrictions!;

    Color bannerColor;
    IconData bannerIcon;

    switch (restrictions.level) {
      case ConsentRestrictionLevel.soft:
        bannerColor = Colors.orange;
        bannerIcon = Icons.warning_amber;
        break;
      case ConsentRestrictionLevel.hard:
        bannerColor = Colors.red;
        bannerIcon = Icons.warning;
        break;
      case ConsentRestrictionLevel.final_:
        bannerColor = Colors.red[800]!;
        bannerIcon = Icons.error;
        break;
      case ConsentRestrictionLevel.deletion:
        bannerColor = Colors.red[900]!;
        bannerIcon = Icons.delete_forever;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(bannerIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.translate('policy_restrictions_title') ?? 'Ограничения доступа',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    restrictions.restrictionMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: bannerColor,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: localizations.translate('accept_policy') ?? 'Принять политику',
          textColor: Colors.white,
          onPressed: () => _showMandatoryPolicyDialog(),
        ),
      ),
    );
  }

  /// Проверяет возможность выполнения действия
  bool canPerformAction(String action) {
    if (_currentRestrictions == null) return true;
    return _consentService.canPerformAction(action, _currentRestrictions!.level);
  }

  /// Показывает сообщение о блокировке действия
  void showActionBlockedMessage(String action) {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    String message;

    switch (action) {
      case 'create_note':
        message = localizations.translate('create_note_blocked') ??
            'Создание заметок заблокировано. Примите политику конфиденциальности.';
        break;
      case 'create_map':
        message = localizations.translate('create_map_blocked') ??
            'Создание карт заблокировано. Примите политику конфиденциальности.';
        break;
      case 'edit_profile':
        message = localizations.translate('edit_profile_blocked') ??
            'Редактирование профиля заблокировано. Примите политику конфиденциальности.';
        break;
      default:
        message = localizations.translate('action_blocked') ??
            'Действие заблокировано. Примите политику конфиденциальности.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: localizations.translate('accept_policy') ?? 'Принять политику',
          textColor: Colors.white,
          onPressed: () => _showMandatoryPolicyDialog(),
        ),
      ),
    );
  }

  /// Безопасное выполнение действия с проверкой ограничений
  Future<bool> safePerformAction(String action, Future<void> Function() actionCallback) async {
    if (!canPerformAction(action)) {
      showActionBlockedMessage(action);
      return false;
    }

    try {
      await actionCallback();
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при выполнении действия $action: $e');
      return false;
    }
  }

  /// Создает виджет с ограничениями
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

  /// Создает заглушку для заблокированного контента
  Widget _buildRestrictedPlaceholder(String action) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 48,
            color: Colors.red[700],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('content_blocked') ?? 'Контент заблокирован',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            localizations.translate('accept_policy_to_unlock') ??
                'Примите политику конфиденциальности для разблокировки',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showMandatoryPolicyDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text(
              localizations.translate('accept_policy') ?? 'Принять политику',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Получает текущие ограничения
  ConsentRestrictionResult? get currentRestrictions => _currentRestrictions;

  /// Есть ли активные ограничения
  bool get hasActiveRestrictions => _currentRestrictions?.hasRestrictions ?? false;

  /// Может ли пользователь создавать контент
  bool get canCreateContent => _currentRestrictions?.canCreateContent ?? true;

  /// Может ли пользователь редактировать профиль
  bool get canEditProfile => _currentRestrictions?.canEditProfile ?? true;
}