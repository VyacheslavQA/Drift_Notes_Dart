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
        // Если файл для текущего языка не найден, загружаем русскую версию
        try {
          guideText = await rootBundle.loadString(
            'assets/user_guide/user_guide_ru.txt',
          );
          print('✅ Successfully loaded fallback Russian version');
        } catch (e2) {
          print('❌ Failed to load Russian version: $e2');
          throw Exception('Cannot load any user guide file');
        }
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
          _guideText = 'Ошибка загрузки руководства пользователя\n\nОшибка: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.textColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
    );
  }
}
