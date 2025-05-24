// Путь: lib/screens/settings/language_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../providers/language_provider.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  LanguageSettingsScreenState createState() => LanguageSettingsScreenState();
}

class LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String? _selectedLanguageCode;
  bool _isSystemLanguage = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLocale = languageProvider.currentLocale;

    // Проверяем, используется ли системный язык
    _isSystemLanguage = await languageProvider.isUsingSystemLanguage();

    setState(() {
      _selectedLanguageCode = _isSystemLanguage ? 'system' : currentLocale.languageCode;
      _isLoading = false;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _selectedLanguageCode = languageCode;
    });

    try {
      if (languageCode == 'system') {
        await languageProvider.setSystemLanguage();
        _isSystemLanguage = true;
      } else {
        await languageProvider.changeLanguage(Locale(languageCode));
        _isSystemLanguage = false;
      }
    } catch (e) {
      // В случае ошибки можно добавить логирование, но уведомление не показываем
      debugPrint('Ошибка при смене языка: $e');
    } finally {
      if (mounted) {
        setState(() {
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
          localizations.translate('language'),
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
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageOption(
            title: localizations.translate('system_language'),
            languageCode: 'system',
            subtitle: 'Использовать язык системы',
            icon: Icons.language,
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            title: 'Русский',
            languageCode: 'ru',
            subtitle: 'Russian',
            icon: Icons.language,
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            title: 'English',
            languageCode: 'en',
            subtitle: 'Английский',
            icon: Icons.language,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String languageCode,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedLanguageCode == languageCode;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
          ),
        ),
        leading: Icon(
          icon,
          color: AppConstants.textColor,
        ),
        trailing: isSelected
            ? Icon(
          Icons.check_circle,
          color: AppConstants.primaryColor,
        )
            : null,
        onTap: () => _changeLanguage(languageCode),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}