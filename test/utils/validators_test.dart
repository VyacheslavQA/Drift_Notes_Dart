// Путь: test/utils/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:drift_notes_dart/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('Email Validation', () {
      test('should validate correct email addresses', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'test123@gmail.com',
          'firstname+lastname@company.org',
          'a@b.co',
        ];

        for (final email in validEmails) {
          final result = Validators.validateEmail(email);
          expect(result, null, reason: 'Failed for email: $email');
        }
      });

      test('should reject invalid email addresses', () {
        final invalidEmails = [
          'invalid-email',
          '@domain.com',
          'user@',
          'user@domain',
          '',
        ];

        for (final email in invalidEmails) {
          final result = Validators.validateEmail(email);
          expect(result, isNotNull, reason: 'Should reject email: $email');
        }
      });

      test('should handle null email', () {
        final result = Validators.validateEmail(null);
        expect(result, isNotNull);
        expect(result, contains('введите email'));
      });
    });

    group('Password Validation', () {
      test('should validate correct passwords', () {
        final validPasswords = [
          'MyPassword123',
          'StrongPass1',
          'AnotherGood1',
          'TestPassword2024',
        ];

        for (final password in validPasswords) {
          final result = Validators.validatePassword(password);
          expect(result, null, reason: 'Failed for password: $password');
        }
      });

      test('should reject weak passwords', () {
        final weakPasswords = [
          'short',           // Слишком короткий
          'nouppercase1',    // Нет заглавных букв
          '',                // Пустой
        ];

        for (final password in weakPasswords) {
          final result = Validators.validatePassword(password);
          expect(result, isNotNull, reason: 'Should reject password: $password');
        }
      });

      test('should handle null password', () {
        final result = Validators.validatePassword(null);
        expect(result, isNotNull);
        expect(result, contains('введите пароль'));
      });

      test('should reject passwords with invalid characters', () {
        final passwordsWithInvalidChars = [
          'Password123«»',   // Недопустимые символы
          'Pass§word1',      // Недопустимый символ
          'Test™Password1',  // Недопустимый символ
        ];

        for (final password in passwordsWithInvalidChars) {
          final result = Validators.validatePassword(password);
          expect(result, isNotNull, reason: 'Should reject password with invalid chars: $password');
        }
      });
    });

    group('Name Validation', () {
      test('should validate correct names', () {
        final validNames = [
          'Иван',
          'Мария',
          'Александр',
          'Анна-Мария',
          'John',
          'Mary Jane',
        ];

        for (final name in validNames) {
          final result = Validators.validateName(name);
          expect(result, null, reason: 'Failed for name: $name');
        }
      });

      test('should reject invalid names', () {
        final invalidNames = [
          '',      // Пустое
          'А',     // Слишком короткое
          '1',     // Слишком короткое
        ];

        for (final name in invalidNames) {
          final result = Validators.validateName(name);
          expect(result, isNotNull, reason: 'Should reject name: $name');
        }
      });

      test('should handle null name', () {
        final result = Validators.validateName(null);
        expect(result, isNotNull);
        expect(result, contains('введите ваше имя'));
      });
    });

    group('Confirm Password Validation', () {
      test('should validate matching passwords', () {
        final password = 'MyPassword123';
        final confirmPassword = 'MyPassword123';

        final result = Validators.validateConfirmPassword(confirmPassword, password);
        expect(result, null);
      });

      test('should reject non-matching passwords', () {
        final password = 'MyPassword123';
        final confirmPassword = 'DifferentPassword';

        final result = Validators.validateConfirmPassword(confirmPassword, password);
        expect(result, isNotNull);
        expect(result, contains('не совпадают'));
      });

      test('should handle null confirm password', () {
        final password = 'MyPassword123';

        final result = Validators.validateConfirmPassword(null, password);
        expect(result, isNotNull);
        expect(result, contains('подтвердите пароль'));
      });

      test('should handle empty confirm password', () {
        final password = 'MyPassword123';

        final result = Validators.validateConfirmPassword('', password);
        expect(result, isNotNull);
        expect(result, contains('подтвердите пароль'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long inputs', () {
        final longEmail = 'a' * 100 + '@example.com';
        final longPassword = 'A' + 'a' * 100 + '1';
        final longName = 'A' * 100;

        // Email может быть длинным, если формат корректный
        expect(Validators.validateEmail(longEmail), null);

        // Пароль может быть длинным
        expect(Validators.validatePassword(longPassword), null);

        // Имя может быть длинным
        expect(Validators.validateName(longName), null);
      });

      test('should handle special characters in allowed contexts', () {
        // Пароль с базовыми символами (ваш валидатор строгий к спец. символам)
        final passwordWithBasicChars = 'MyPassword123';
        expect(Validators.validatePassword(passwordWithBasicChars), null);

        // Email с разрешенными символами
        final emailWithDots = 'first.last@example.com';
        expect(Validators.validateEmail(emailWithDots), null);
      });

      test('should be consistent with validation rules', () {
        // Проверяем согласованность валидации
        final testPassword = 'TestPass123';

        // Пароль должен быть валидным
        expect(Validators.validatePassword(testPassword), null);

        // Подтверждение того же пароля должно быть валидным
        expect(Validators.validateConfirmPassword(testPassword, testPassword), null);

        // Подтверждение другого пароля должно быть невалидным
        expect(Validators.validateConfirmPassword('DifferentPass', testPassword), isNotNull);
      });
    });
  });
}