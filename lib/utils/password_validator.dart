// Файл: lib/utils/password_validator.dart

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

enum PasswordRule {
  minLength,
  hasUppercase,
  hasDigit,
  noSpecialChars,
}

class PasswordValidationResult {
  final List<PasswordRule> violatedRules;
  final bool isValid;

  PasswordValidationResult({
    required this.violatedRules,
    required this.isValid,
  });

  /// Получить сообщение для конкретного нарушенного правила
  String getMessageForRule(PasswordRule rule, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (rule) {
      case PasswordRule.minLength:
        return localizations.translate('password_min_8_chars') ??
            'Пароль должен содержать минимум 8 символов';
      case PasswordRule.hasUppercase:
        return localizations.translate('password_needs_uppercase') ??
            'Добавьте хотя бы одну заглавную букву (A-Z)';
      case PasswordRule.hasDigit:
        return localizations.translate('password_needs_digit') ??
            'Добавьте хотя бы одну цифру (0-9)';
      case PasswordRule.noSpecialChars:
        return localizations.translate('password_no_special_chars') ??
            'Пароль не должен содержать специальные символы';
    }
  }

  /// Получить первое сообщение об ошибке (для обратной совместимости с FormField)
  String? getFirstErrorMessage(BuildContext context) {
    if (isValid) return null;
    if (violatedRules.isEmpty) return null;

    return getMessageForRule(violatedRules.first, context);
  }

  /// Получить все сообщения об ошибках
  List<String> getAllErrorMessages(BuildContext context) {
    return violatedRules.map((rule) => getMessageForRule(rule, context)).toList();
  }
}

class PasswordValidator {
  static const int minPasswordLength = 8;

  /// Регулярное выражение для разрешенных символов (только буквы и цифры)
  static final RegExp _allowedCharsRegex = RegExp(r'^[a-zA-Z0-9]*$');

  /// Регулярное выражение для поиска заглавных букв
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');

  /// Регулярное выражение для поиска цифр
  static final RegExp _digitRegex = RegExp(r'[0-9]');

  /// Детальная валидация пароля с возвратом всех нарушенных правил
  static PasswordValidationResult validatePasswordDetailed(String password) {
    List<PasswordRule> violatedRules = [];

    // Проверка на минимальную длину
    if (password.length < minPasswordLength) {
      violatedRules.add(PasswordRule.minLength);
    }

    // Проверка на наличие заглавной буквы
    if (!_uppercaseRegex.hasMatch(password)) {
      violatedRules.add(PasswordRule.hasUppercase);
    }

    // Проверка на наличие цифры
    if (!_digitRegex.hasMatch(password)) {
      violatedRules.add(PasswordRule.hasDigit);
    }

    // Проверка на отсутствие специальных символов
    if (!_allowedCharsRegex.hasMatch(password)) {
      violatedRules.add(PasswordRule.noSpecialChars);
    }

    return PasswordValidationResult(
      violatedRules: violatedRules,
      isValid: violatedRules.isEmpty,
    );
  }

  /// Простая валидация для обратной совместимости с TextFormField
  static String? validatePassword(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).translate('please_enter_password') ?? 'Пожалуйста, введите пароль'
          : 'Пожалуйста, введите пароль';
    }

    final result = validatePasswordDetailed(value);

    // Если контекст не передан, возвращаем fallback сообщения на русском
    if (context == null) {
      if (result.isValid) return null;
      if (result.violatedRules.isEmpty) return null;

      // Возвращаем первое нарушение с русским текстом
      switch (result.violatedRules.first) {
        case PasswordRule.minLength:
          return 'Пароль должен содержать минимум 8 символов';
        case PasswordRule.hasUppercase:
          return 'Добавьте хотя бы одну заглавную букву (A-Z)';
        case PasswordRule.hasDigit:
          return 'Добавьте хотя бы одну цифру (0-9)';
        case PasswordRule.noSpecialChars:
          return 'Пароль не должен содержать специальные символы';
      }
    }

    return result.getFirstErrorMessage(context);
  }

  /// Проверка конкретного правила
  static bool checkRule(String password, PasswordRule rule) {
    switch (rule) {
      case PasswordRule.minLength:
        return password.length >= minPasswordLength;
      case PasswordRule.hasUppercase:
        return _uppercaseRegex.hasMatch(password);
      case PasswordRule.hasDigit:
        return _digitRegex.hasMatch(password);
      case PasswordRule.noSpecialChars:
        return _allowedCharsRegex.hasMatch(password);
    }
  }

  /// Получить список всех правил
  static List<PasswordRule> getAllRules() {
    return [
      PasswordRule.minLength,
      PasswordRule.hasUppercase,
      PasswordRule.hasDigit,
      PasswordRule.noSpecialChars,
    ];
  }

  /// Получить краткое описание правила для UI
  static String getRuleDescription(PasswordRule rule, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (rule) {
      case PasswordRule.minLength:
        return localizations.translate('password_min_chars') ?? 'Мин. 8 символов';
      case PasswordRule.hasUppercase:
        return 'A-Z';
      case PasswordRule.hasDigit:
        return '0-9';
      case PasswordRule.noSpecialChars:
        return localizations.translate('password_no_special') ?? 'Без спецсимволов';
    }
  }
}