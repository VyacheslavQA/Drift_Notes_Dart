// Путь: lib/utils/validators.dart

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

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
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return context != null
          ? AppLocalizations.of(context).translate('enter_valid_email')
          : 'Введите корректный email адрес';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // Проверка пароля
  static String? validatePassword(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).translate('please_enter_password')
          : 'Пожалуйста, введите пароль';
    }

    if (value.length < 8) {
      return context != null
          ? AppLocalizations.of(context).translate('password_min_8_chars')
          : 'Пароль должен содержать минимум 8 символов';
    }

    // Проверка на наличие хотя бы одной заглавной буквы
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return context != null
          ? AppLocalizations.of(context).translate('password_needs_uppercase')
          : 'Пароль должен содержать хотя бы одну заглавную букву';
    }

    // Проверка на отсутствие специфичных символов, кроме разрешенных
    // Разрешаем только буквы, цифры и некоторые специальные символы
    final RegExp allowedCharsRegex = RegExp(
      r'^[a-zA-Z0-9@#$%^&*()_+\-=\[\]{}|;:,.<>?]*$',
    );

    if (!allowedCharsRegex.hasMatch(value)) {
      return context != null
          ? AppLocalizations.of(context).translate('password_invalid_chars')
          : 'Пароль содержит недопустимые символы';
    }

    return null; // Возвращаем null если проверка успешна
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
