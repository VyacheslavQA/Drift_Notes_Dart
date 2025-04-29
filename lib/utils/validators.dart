// Путь: lib/utils/validators.dart

class Validators {
  // Проверка Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }

    // Простая регулярка для проверки формата email
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email адрес';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // Проверка пароля
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }

    if (value.length < 8) {
      return 'Пароль должен содержать минимум 8 символов';
    }

    // Проверка на наличие хотя бы одной заглавной буквы
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Пароль должен содержать хотя бы одну заглавную букву';
    }

    // Проверка на отсутствие специфичных символов, кроме разрешенных
    // Разрешаем только буквы, цифры и некоторые специальные символы
    final RegExp allowedCharsRegex = RegExp(r'^[a-zA-Z0-9@#$%^&*()_+\-=\[\]{}|;:,.<>?]*$');

    if (!allowedCharsRegex.hasMatch(value)) {
      return 'Пароль содержит недопустимые символы';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // Проверка имени пользователя
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите ваше имя';
    }

    if (value.length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }

    return null; // Возвращаем null если проверка успешна
  }

  // Проверка подтверждения пароля
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, подтвердите пароль';
    }

    if (value != password) {
      return 'Пароли не совпадают';
    }

    return null; // Возвращаем null если проверка успешна
  }
}