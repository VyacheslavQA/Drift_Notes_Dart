// Файл: lib/utils/validators.dart

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'password_validator.dart'; // ✅ ДОБАВЛЕН ИМПОРТ

class Validators {
  // Проверка Email
  static String? validateEmail(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).translate('please_enter_email')
          : 'Пожалуйста, введите email';
    }

    // Простая регулярка для проверки формата email
    final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'   // ← без запятой
    );

    if (!emailRegex.hasMatch(value)) {
      return context != null
          ? AppLocalizations.of(context).translate('enter_valid_email')
          : 'Введите корректный email адрес';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // ✅ ДЕЛЕГИРОВАНИЕ: Проверка пароля теперь использует PasswordValidator
  static String? validatePassword(String? value, [BuildContext? context]) {
    return PasswordValidator.validatePassword(value, context);
  }

  // Проверка имени пользователя
  static String? validateName(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).translate('please_enter_name')
          : 'Пожалуйста, введите ваше имя';
    }

    if (value.length < 2) {
      return context != null
          ? AppLocalizations.of(context).translate('name_min_2_chars')
          : 'Имя должно содержать минимум 2 символа';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // Проверка подтверждения пароля
  static String? validateConfirmPassword(
      String? value,
      String password, [
        BuildContext? context,
      ]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).translate('please_confirm_password')
          : 'Пожалуйста, подтвердите пароль';
    }

    if (value != password) {
      return context != null
          ? AppLocalizations.of(context).translate('passwords_dont_match')
          : 'Пароли не совпадают';
    }

    return null; // Возвращаем null если проверка успешна
  }
}