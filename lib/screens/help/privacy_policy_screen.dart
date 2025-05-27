// Путь: lib/screens/help/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String _policyText = '';
  bool _isLoading = true;
  bool _hasLoadedOnce = false; // Флаг для предотвращения повторной загрузки

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Загружаем только один раз
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadPrivacyPolicy();
    }
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // Отладочные сообщения
      print('🔍 Language code: $languageCode');
      print('🔍 Full locale: ${localizations.locale}');

      // Пробуем загрузить файл для текущего языка
      final fileName = 'assets/privacy_policy/privacy_policy_$languageCode.txt';
      print('🔍 Trying to load file: $fileName');

      String policyText;
      try {
        policyText = await rootBundle.loadString(fileName);
        print('✅ Successfully loaded $fileName');
      } catch (e) {
        print('❌ Failed to load $fileName: $e');
        // Если файл для текущего языка не найден, загружаем английскую версию
        try {
          policyText = await rootBundle.loadString('assets/privacy_policy/privacy_policy_en.txt');
          print('✅ Successfully loaded fallback English version');
        } catch (e2) {
          print('❌ Failed to load English version: $e2');
          throw Exception('Cannot load any privacy policy file');
        }
      }

      if (mounted) {
        setState(() {
          _policyText = policyText;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Critical error in _loadPrivacyPolicy: $e');
      if (mounted) {
        setState(() {
          _policyText = 'Ошибка загрузки политики конфиденциальности\n\nОшибка: $e';
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
          localizations.translate('privacy_policy'),
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
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
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
            _policyText,
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