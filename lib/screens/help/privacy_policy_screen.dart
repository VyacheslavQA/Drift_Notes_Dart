// Файл: lib/screens/help/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // URL политики конфиденциальности на сайте
  static const String _privacyPolicyUrl = 'https://driftnotesapp.com/privacy-policy.html';

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

      // Пробуем загрузить файл для текущего языка с версией
      final fileName = 'assets/privacy_policy/privacy_policy_${languageCode}_1.0.0.txt';
      print('🔍 Trying to load file: $fileName');

      String policyText;
      try {
        policyText = await rootBundle.loadString(fileName);
        print('✅ Successfully loaded $fileName');
      } catch (e) {
        print('❌ Failed to load $fileName: $e');
        // Если файл для текущего языка не найден, загружаем английскую версию
        try {
          policyText = await rootBundle.loadString(
            'assets/privacy_policy/privacy_policy_en_1.0.0.txt',
          );
          print('✅ Successfully loaded fallback English version');
        } catch (e2) {
          print('❌ Failed to load English version: $e2');
          // Если и версия с номером не найдена, пробуем старый формат
          try {
            policyText = await rootBundle.loadString(
              'assets/privacy_policy/privacy_policy_en.txt',
            );
            print('✅ Successfully loaded legacy English version');
          } catch (e3) {
            print('❌ Failed to load any version: $e3');
            throw Exception('Cannot load any privacy policy file');
          }
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
          _policyText =
          'Ошибка загрузки политики конфиденциальности\n\nОшибка: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPrivacyPolicyWebsite() async {
    try {
      final Uri url = Uri.parse(_privacyPolicyUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('could_not_open_link')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening URL: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('error_opening_link')),
            backgroundColor: Colors.red,
          ),
        );
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
          valueColor: AlwaysStoppedAnimation<Color>(
            AppConstants.textColor,
          ),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ссылка на сайт
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openPrivacyPolicyWebsite,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.textColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          color: AppConstants.textColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('view_on_website'),
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizations.translate('current_privacy_policy_version'),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Основной текст политики
            Container(
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
          ],
        ),
      ),
    );
  }
}