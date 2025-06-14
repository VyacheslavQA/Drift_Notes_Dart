import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift_notes_dart/providers/language_provider.dart';

void main() {
  group('LanguageProvider Tests', () {
    late LanguageProvider languageProvider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Мокаем SharedPreferences для тестов
      SharedPreferences.setMockInitialValues({});
      languageProvider = LanguageProvider();

      // Ждем инициализации провайдера
      await Future.delayed(Duration(milliseconds: 200));
    });

    test('language provider should be created successfully', () {
      expect(languageProvider, isNotNull);
      expect(languageProvider, isA<LanguageProvider>());
    });

    test('should have default locale', () {
      expect(languageProvider.currentLocale, isA<Locale>());
      expect(languageProvider.languageCode, isNotEmpty);
    });

    test('should change language successfully', () async {
      final initialLanguage = languageProvider.languageCode;

      // Меняем язык на английский
      await languageProvider.changeLanguage(const Locale('en'));

      expect(languageProvider.languageCode, equals('en'));
      expect(languageProvider.currentLocale.languageCode, equals('en'));
    });

    test('should not change if same language is set', () async {
      await languageProvider.changeLanguage(const Locale('ru'));
      final initialLanguage = languageProvider.languageCode;

      // Пытаемся установить тот же язык
      await languageProvider.changeLanguage(const Locale('ru'));

      expect(languageProvider.languageCode, equals(initialLanguage));
    });

    test('should get correct language names', () {
      expect(languageProvider.getLanguageName('ru'), equals('Русский'));
      expect(languageProvider.getLanguageName('en'), equals('English'));
      expect(languageProvider.getLanguageName('unknown'), equals('Unknown'));
    });

    test('should provide supported languages list', () {
      final languages = languageProvider.getSupportedLanguages();

      expect(languages, isA<List<Map<String, String>>>());
      expect(languages.length, greaterThanOrEqualTo(2));

      // Проверяем, что есть русский и английский
      final languageCodes = languages.map((lang) => lang['code']).toList();
      expect(languageCodes, contains('ru'));
      expect(languageCodes, contains('en'));
    });

    test('should reset to default language', () async {
      // Сначала меняем язык
      await languageProvider.changeLanguage(const Locale('en'));
      expect(languageProvider.languageCode, equals('en'));

      // Затем сбрасываем к умолчанию
      await languageProvider.resetToDefault();

      expect(languageProvider.languageCode, equals('ru'));
      expect(languageProvider.currentLocale.languageCode, equals('ru'));
    });

    test('should handle system language setting', () async {
      await languageProvider.setSystemLanguage();

      // Проверяем, что язык установлен (может быть любой поддерживаемый)
      expect(['ru', 'en'], contains(languageProvider.languageCode));
    });

    test('should check if using system language', () async {
      // По умолчанию не используем системный язык
      bool isSystemLanguage = await languageProvider.isUsingSystemLanguage();
      expect(isSystemLanguage, isFalse);

      // Устанавливаем системный язык
      await languageProvider.setSystemLanguage();

      // Теперь должен использоваться системный
      isSystemLanguage = await languageProvider.isUsingSystemLanguage();
      expect(isSystemLanguage, isTrue);
    });

    test('should get device locale', () async {
      final deviceLocale = await LanguageProvider.getDeviceLocale();

      expect(deviceLocale, isA<Locale>());
      expect(['ru', 'en'], contains(deviceLocale.languageCode));
    });

    test('should persist language in SharedPreferences', () async {
      // Меняем язык
      await languageProvider.changeLanguage(const Locale('en'));

      // Создаем новый экземпляр провайдера
      final newProvider = LanguageProvider();
      await Future.delayed(Duration(milliseconds: 200));

      // Язык должен загрузиться из сохраненных настроек
      expect(newProvider.languageCode, equals('en'));
    });

    test('should notify listeners on language change', () async {
      bool notified = false;
      languageProvider.addListener(() {
        notified = true;
      });

      await languageProvider.changeLanguage(const Locale('en'));

      expect(notified, isTrue);
    });
  });
}