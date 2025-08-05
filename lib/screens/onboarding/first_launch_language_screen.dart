// Путь: lib/screens/onboarding/first_launch_language_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../services/firebase/firebase_service.dart';
import '../../localization/app_localizations.dart';

class FirstLaunchLanguageScreen extends StatefulWidget {
  const FirstLaunchLanguageScreen({super.key});

  @override
  State<FirstLaunchLanguageScreen> createState() => _FirstLaunchLanguageScreenState();
}

class _FirstLaunchLanguageScreenState extends State<FirstLaunchLanguageScreen>
    with TickerProviderStateMixin {
  String? _selectedLanguageCode;
  bool _isLoading = false;
  final _firebaseService = FirebaseService();

  // Анимации
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();

    // Устанавливаем русский как выбранный по умолчанию
    _selectedLanguageCode = 'ru';
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _slideAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (_isLoading) return;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedLanguageCode = languageCode;
    });

    // УБРАНО: Не применяем язык сразу, только при нажатии "Продолжить"
  }

  Future<void> _continueWithSelectedLanguage() async {
    if (_isLoading || _selectedLanguageCode == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // Устанавливаем выбранный язык
      await languageProvider.changeLanguage(Locale(_selectedLanguageCode!));

      // Сохраняем флаг, что пользователь уже выбрал язык при первом запуске
      await _markLanguageSelectionCompleted();

      // ИЗМЕНЕНО: Переходим сразу на экран авторизации или домашний экран
      if (mounted) {
        if (_firebaseService.isUserLoggedIn) {
          // Если пользователь уже авторизован, переходим на домашний экран
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Если не авторизован, переходим на экран выбора способа авторизации
          Navigator.of(context).pushReplacementNamed('/auth_selection');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка при установке языка: $e');
      // В случае ошибки всё равно продолжаем
      if (mounted) {
        if (_firebaseService.isUserLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/auth_selection');
        }
      }
    }
  }

  Future<void> _markLanguageSelectionCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('language_selection_completed', true);
      debugPrint('✅ Флаг выбора языка сохранен');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении флага выбора языка: $e');
    }
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String languageCode,
    required IconData icon,
  }) {
    final isSelected = _selectedLanguageCode == languageCode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectLanguage(languageCode),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.textColor.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppConstants.textColor
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.textColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppConstants.textColor
                        : Colors.white.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppConstants.textColor
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? AppConstants.textColor.withOpacity(0.8)
                              : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppConstants.textColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _continueWithSelectedLanguage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.textColor,
          foregroundColor: Colors.black,
          elevation: _isLoading ? 0 : 4,
          shadowColor: AppConstants.textColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: AppConstants.textColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getLoadingText(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        )
            : Text(
          _getContinueText(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Получаем текст кнопки в зависимости от выбранного языка
  String _getContinueText() {
    switch (_selectedLanguageCode) {
      case 'en':
        return 'Continue';
      case 'kk':
        return 'Жалғастыру';
      case 'ru':
      default:
        return 'Продолжить';
    }
  }

  // Получаем текст загрузки в зависимости от выбранного языка
  String _getLoadingText() {
    switch (_selectedLanguageCode) {
      case 'en':
        return 'Applying...';
      case 'kk':
        return 'Қолданылуда...';
      case 'ru':
      default:
        return 'Применяем...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40.0 : 24.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    // Заголовок (статичный, не переводится)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Выберите язык / Select Language',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Список языков
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 500 : double.infinity,
                          ),
                          child: Column(
                            children: [
                              _buildLanguageOption(
                                title: 'Русский',
                                subtitle: 'Russian',
                                languageCode: 'ru',
                                icon: Icons.language,
                              ),
                              _buildLanguageOption(
                                title: 'English',
                                subtitle: 'Английский',
                                languageCode: 'en',
                                icon: Icons.language,
                              ),
                              _buildLanguageOption(
                                title: 'Қазақша',
                                subtitle: 'Казахский',
                                languageCode: 'kk',
                                icon: Icons.language,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Кнопка продолжить
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: _buildContinueButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}