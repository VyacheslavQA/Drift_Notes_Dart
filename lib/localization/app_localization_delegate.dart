// Путь: lib/localization/app_localization_delegate.dart

import 'package:flutter/material.dart';
import 'app_localizations.dart';

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  // Проверка, поддерживается ли заданный язык
  @override
  bool isSupported(Locale locale) {
    // Проверяем, есть ли язык в списке поддерживаемых
    return ['ru', 'en'].contains(locale.languageCode);
  }

  // Загрузка ресурсов для нужного языка
  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  // Проверка, нужно ли перезагружать ресурсы при изменении языка
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
