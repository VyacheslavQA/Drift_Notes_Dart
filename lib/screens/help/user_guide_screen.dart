// Путь: lib/screens/help/user_guide_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  String _guideText = '';
  bool _isLoading = true;
  bool _hasLoadedOnce = false; // Флаг для предотвращения повторной загрузки

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Загружаем только один раз
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadUserGuide();
    }
  }

  Future<void> _loadUserGuide() async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // Отладочные сообщения
      print('🔍 Language code: $languageCode');
      print('🔍 Full locale: ${localizations.locale}');

      // Пробуем загрузить файл для текущего языка
      final fileName = 'assets/user_guide/user_guide_$languageCode.txt';
      print('🔍 Trying to load file: $fileName');

      String guideText;
      try {
        guideText = await rootBundle.loadString(fileName);
        print('✅ Successfully loaded $fileName');
      } catch (e) {
        print('❌ Failed to load $fileName: $e');
        // Если файл для текущего языка не найден, пробуем загрузить по приоритету
        guideText = await _loadFallbackGuide(languageCode);
      }

      if (mounted) {
        setState(() {
          _guideText = guideText;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Critical error in _loadUserGuide: $e');
      if (mounted) {
        setState(() {
          _guideText = _getErrorMessage();
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _loadFallbackGuide(String languageCode) async {
    // Определяем порядок fallback в зависимости от языка
    List<String> fallbackOrder;

    switch (languageCode) {
      case 'kk': // Казахский
        fallbackOrder = ['ru', 'en']; // Для казахского сначала русский, потом английский
        break;
      case 'ru': // Русский
        fallbackOrder = ['en', 'kk']; // Для русского сначала английский, потом казахский
        break;
      case 'en': // Английский
        fallbackOrder = ['ru', 'kk']; // Для английского сначала русский, потом казахский
        break;
      default:
        fallbackOrder = ['ru', 'en', 'kk']; // По умолчанию
        break;
    }

    // Пробуем загрузить файлы в порядке приоритета
    for (String fallbackLang in fallbackOrder) {
      try {
        final fallbackFileName = 'assets/user_guide/user_guide_$fallbackLang.txt';
        print('🔄 Trying fallback file: $fallbackFileName');

        final guideText = await rootBundle.loadString(fallbackFileName);
        print('✅ Successfully loaded fallback $fallbackFileName');
        return guideText;
      } catch (e) {
        print('❌ Failed to load fallback $fallbackLang: $e');
        continue;
      }
    }

    // Если все файлы недоступны
    throw Exception('Cannot load any user guide file');
  }

  String _getErrorMessage() {
    final localizations = AppLocalizations.of(context);
    final languageCode = localizations.locale.languageCode;

    switch (languageCode) {
      case 'kk':
        return 'Пайдаланушы нұсқаулығын жүктеу кезінде қате орын алды\n\nКейінірек қайта көріңіз немесе техникалық қолдауға хабарласыңыз: support@driftnotes.com';
      case 'en':
        return 'Error loading user guide\n\nPlease try again later or contact technical support: support@driftnotes.com';
      default: // ru
        return 'Ошибка загрузки руководства пользователя\n\nПопробуйте позже или обратитесь в техническую поддержку: support@driftnotes.com';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Получаем размеры системных панелей
    final bottomPadding = mediaQuery.padding.bottom;
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('user_guide'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        // Используем SafeArea для базовой защиты
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.textColor,
            ),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  // Добавляем дополнительный отступ снизу для надежности
                  bottom: 16 + (bottomPadding > 0 ? 8 : 16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppConstants.textColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _guideText,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}