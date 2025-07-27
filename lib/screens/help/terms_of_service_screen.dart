// Путь: lib/screens/help/terms_of_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  String _termsText = '';
  bool _isLoading = true;
  bool _hasLoadedOnce = false; // Флаг для предотвращения повторной загрузки

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Загружаем только один раз
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadTermsOfService();
    }
  }

  Future<void> _loadTermsOfService() async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // Отладочные сообщения
      print('🔍 Language code: $languageCode');
      print('🔍 Full locale: ${localizations.locale}');

      // Пробуем загрузить файл для текущего языка с версией
      final fileName = 'assets/terms_of_service/terms_of_service_${languageCode}_1.0.0.txt';
      print('🔍 Trying to load file: $fileName');

      String termsText;
      try {
        termsText = await rootBundle.loadString(fileName);
        print('✅ Successfully loaded $fileName');
      } catch (e) {
        print('❌ Failed to load $fileName: $e');
        // Если файл для текущего языка не найден, загружаем английскую версию
        try {
          termsText = await rootBundle.loadString(
            'assets/terms_of_service/terms_of_service_en_1.0.0.txt',
          );
          print('✅ Successfully loaded fallback English version');
        } catch (e2) {
          print('❌ Failed to load English version: $e2');
          // Если и версия с номером не найдена, пробуем старый формат
          try {
            termsText = await rootBundle.loadString(
              'assets/terms_of_service/terms_of_service_en.txt',
            );
            print('✅ Successfully loaded legacy English version');
          } catch (e3) {
            print('❌ Failed to load any version: $e3');
            throw Exception('Cannot load any terms of service file');
          }
        }
      }

      if (mounted) {
        setState(() {
          _termsText = termsText;
          _isLoading = false;
        });
        print('✅ Terms of service loaded and displayed');
      }
    } catch (e) {
      print('❌ Error loading terms of service: $e');
      if (mounted) {
        setState(() {
          _termsText =
          'Ошибка загрузки пользовательского соглашения.\nError loading terms of service.';
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
          localizations.translate('terms_of_service'),
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
            AppConstants.primaryColor,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppConstants.textColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                localizations.translate('terms_of_service'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Текст пользовательского соглашения
              Text(
                _termsText,
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}