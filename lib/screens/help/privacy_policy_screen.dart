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

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // Загружаем политику в зависимости от языка
      final fileName = 'assets/privacy_policy/privacy_policy_$languageCode.txt';

      String policyText;
      try {
        policyText = await rootBundle.loadString(fileName);
      } catch (e) {
        // Если файл для текущего языка не найден, загружаем английскую версию
        policyText = await rootBundle.loadString('assets/privacy_policy/privacy_policy_en.txt');
      }

      setState(() {
        _policyText = policyText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _policyText = 'Ошибка загрузки политики конфиденциальности / Privacy Policy loading error';
        _isLoading = false;
      });
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