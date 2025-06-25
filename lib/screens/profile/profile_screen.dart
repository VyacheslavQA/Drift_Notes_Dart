// Путь: lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../repositories/user_repository.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/geography_service.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../services/auth/google_sign_in_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();
  final _firebaseService = FirebaseService();
  final _geographyService = GeographyService();
  final _formKey = GlobalKey<FormState>();
  final _googleSignInService = GoogleSignInService();

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;

  String? _selectedCountry;
  String? _selectedCity;
  List<String> _availableCountries = [];
  List<String> _availableCities = [];
  String? _selectedExperience;
  List<String> _selectedFishingTypes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingCountries = false;
  bool _isLoadingCities = false;

  // Сохраненные ключи из базы данных
  String? _savedCountryKey;
  String? _savedCityKey;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _initializeProfile();
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Полная инициализация профиля
  Future<void> _initializeProfile() async {
    try {
      // 1. Загружаем данные пользователя
      await _loadUserData();

      // 2. Загружаем список стран
      await _loadCountries();

      // 3. Если есть сохраненная страна - устанавливаем её и загружаем города
      if (_savedCountryKey != null) {
        await _setCountryAndCity();
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации профиля: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Загрузка данных пользователя
  Future<void> _loadUserData() async {
    try {
      final userData = await _userRepository.getCurrentUserData();

      if (userData != null) {
        _displayNameController.text = userData.displayName ?? '';
        _emailController.text = userData.email;
        _selectedExperience = userData.experience;
        _selectedFishingTypes = List<String>.from(userData.fishingTypes);

        // Сохраняем ключи
        _savedCountryKey = userData.country;
        _savedCityKey = userData.city;
      } else {
        // Данные из FirebaseAuth если нет в Firestore
        final user = _firebaseService.currentUser;
        if (user != null) {
          _displayNameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки данных пользователя: $e');
    }
  }

  // Загрузка списка стран
  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
    });

    try {
      final countries = await _geographyService.getLocalizedCountries(context);
      setState(() {
        _availableCountries = countries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
      });
      debugPrint('❌ Ошибка загрузки стран: $e');
    }
  }

  // Установка страны и города из сохраненных данных
  Future<void> _setCountryAndCity() async {
    if (_savedCountryKey == null || _availableCountries.isEmpty) return;

    try {
      // 1. Находим и устанавливаем страну
      String? countryName = await _geographyService.getCountryNameByKey(
        _savedCountryKey!,
        context,
      );

      // Если не нашли по ключу, может быть ключ уже является названием
      if (countryName == null &&
          _availableCountries.contains(_savedCountryKey!)) {
        countryName = _savedCountryKey!;
      }

      if (countryName != null && _availableCountries.contains(countryName)) {
        setState(() {
          _selectedCountry = countryName;
        });

        // 2. Загружаем города для этой страны
        await _loadCitiesForCountry(countryName, autoSetCity: true);
      }
    } catch (e) {
      debugPrint('❌ Ошибка установки страны и города: $e');
    }
  }

  // Загрузка городов для страны
  Future<void> _loadCitiesForCountry(
      String country, {
        bool autoSetCity = false,
      }) async {
    setState(() {
      _isLoadingCities = true;
      _availableCities = [];
      if (!autoSetCity) {
        _selectedCity = null; // Сбрасываем только при ручном выборе
      }
    });

    try {
      final cities = await _geographyService.getLocalizedCitiesForCountry(
        country,
        context,
      );
      setState(() {
        _availableCities = cities;
        _isLoadingCities = false;
      });

      // Если это автоматическая установка и есть сохраненный город
      if (autoSetCity && _savedCityKey != null) {
        await _setCityFromKey();
      }
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      debugPrint('❌ Ошибка загрузки городов: $e');
    }
  }

  // Установка города из ключа
  Future<void> _setCityFromKey() async {
    if (_savedCityKey == null ||
        _availableCities.isEmpty ||
        _selectedCountry == null)
      return;

    try {
      // Сначала получаем ключ страны по её названию
      String? countryKey = await _geographyService.getCountryKeyByName(
        _selectedCountry!,
        context,
      );
      if (countryKey == null) return;

      String? cityName = await _geographyService.getCityNameByKey(
        _savedCityKey!,
        countryKey,
        context,
      );

      // Если не нашли по ключу, может быть ключ уже является названием
      if (cityName == null && _availableCities.contains(_savedCityKey!)) {
        cityName = _savedCityKey!;
      }

      if (cityName != null && _availableCities.contains(cityName)) {
        setState(() {
          _selectedCity = cityName;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка установки города: $e');
    }
  }

  // Сохранение профиля
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Получаем ключи для сохранения
      String? countryKey;
      String? cityKey;

      if (_selectedCountry != null) {
        countryKey = await _geographyService.getCountryKeyByName(
          _selectedCountry!,
          context,
        );
        countryKey ??= _selectedCountry; // fallback
      }

      if (_selectedCity != null && _selectedCountry != null) {
        cityKey = await _geographyService.getCityKeyByName(
          _selectedCity!,
          _selectedCountry!,
          context,
        );
        cityKey ??= _selectedCity; // fallback
      }

      // Сохраняем данные
      final userData = {
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim(), // ← ДОБАВЛЯЕМ EMAIL!
        'country': countryKey ?? '',
        'city': cityKey ?? '',
        'experience': _selectedExperience,
        'fishingTypes': _selectedFishingTypes,
      };

      await _userRepository.updateUserData(userData);

      // Обновляем имя в FirebaseAuth
      final user = _firebaseService.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
      }

      // Обновляем сохраненные ключи
      _savedCountryKey = countryKey;
      _savedCityKey = cityKey;

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('profile_updated_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('profile_update_error')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleFishingType(String type) {
    setState(() {
      if (_selectedFishingTypes.contains(type)) {
        _selectedFishingTypes.remove(type);
      } else {
        _selectedFishingTypes.add(type);
      }
    });
  }

  // Показать диалог удаления аккаунта
  Future<void> _showDeleteAccountDialog() async {
    final localizations = AppLocalizations.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const DeleteAccountDialog();
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  // Удаление аккаунта
  Future<void> _deleteAccount() async {
    final localizations = AppLocalizations.of(context);

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 16),
              Text(
                localizations.translate('deleting_account'),
                style: TextStyle(color: AppConstants.textColor, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Удаляем аккаунт через FirebaseService
      await _firebaseService.deleteAccount(context);

      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Показываем сообщение об успешном удалении
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('account_deleted_successfully'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Ждем немного для показа сообщения, затем выходим из всех экранов
        await Future.delayed(const Duration(seconds: 1));

        // Закрываем все экраны до корневого
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Заменяем корневой экран на экран с сообщением об удалении
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => Scaffold(
              backgroundColor: AppConstants.backgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'Аккаунт успешно удален',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пожалуйста, перезапустите приложение',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Закрываем диалог загрузки
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Показываем ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_deleting_account')}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
        title: Text(localizations.translate('profile_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body:
      _isLoading
          ? Center(
        child: CircularProgressIndicator(color: AppConstants.textColor),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Имя пользователя
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('name'),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations.translate('please_enter_name');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email (не редактируемый)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              // Выпадающий список стран
              _buildCountryDropdown(localizations),

              const SizedBox(height: 16),

              // Выпадающий список городов
              _buildCityDropdown(localizations),

              const SizedBox(height: 24),

              // Уровень опыта
              Text(
                localizations.translate('experience_level'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children:
                AppConstants.experienceLevels.map((levelKey) {
                  String translatedLevel = localizations.translate(
                    levelKey,
                  );

                  return ChoiceChip(
                    label: Text(translatedLevel),
                    selected: _selectedExperience == levelKey,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedExperience = levelKey;
                        });
                      }
                    },
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color:
                      _selectedExperience == levelKey
                          ? AppConstants.textColor
                          : AppConstants.textColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    backgroundColor: AppConstants.surfaceColor,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Типы рыбалки
              Text(
                localizations.translate('preferred_fishing_types'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children:
                AppConstants.fishingTypes.map((typeKey) {
                  String translatedType = localizations.translate(
                    typeKey,
                  );

                  return FilterChip(
                    label: Text(translatedType),
                    selected: _selectedFishingTypes.contains(
                      typeKey,
                    ),
                    onSelected: (_) => _toggleFishingType(typeKey),
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color:
                      _selectedFishingTypes.contains(typeKey)
                          ? AppConstants.textColor
                          : AppConstants.textColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    backgroundColor: AppConstants.surfaceColor,
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child:
                  _isSaving
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppConstants.textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    localizations.translate('save'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Секция "Опасная зона"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          localizations.translate('danger_zone'),
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      localizations.translate(
                        'delete_account_warning_text',
                      ),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      localizations.translate(
                        'this_action_cannot_be_undone',
                      ),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteAccountDialog,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        label: Text(
                          localizations.translate(
                            'delete_account_permanently',
                          ),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown(AppLocalizations localizations) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: localizations.translate('country'),
        prefixIcon: const Icon(Icons.public),
        suffixIcon:
        _isLoadingCountries
            ? SizedBox(
          width: 20,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.textColor,
            ),
          ),
        )
            : null,
      ),
      isExpanded: true,
      value:
      (_selectedCountry != null &&
          _availableCountries.contains(_selectedCountry!))
          ? _selectedCountry
          : null,
      hint: Text(
        _isLoadingCountries
            ? localizations.translate('loading')
            : localizations.translate('select_country'),
      ),
      items:
      _availableCountries.map((country) {
        return DropdownMenuItem<String>(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged:
      _isLoadingCountries
          ? null
          : (value) {
        if (value != null) {
          setState(() {
            _selectedCountry = value;
            _selectedCity = null;
            _savedCityKey = null;
          });
          _loadCitiesForCountry(value);
        }
      },
    );
  }

  Widget _buildCityDropdown(AppLocalizations localizations) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: localizations.translate('city'),
        prefixIcon: const Icon(Icons.location_city),
        suffixIcon:
        _isLoadingCities
            ? SizedBox(
          width: 20,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.textColor,
            ),
          ),
        )
            : null,
      ),
      isExpanded: true,
      value:
      (_selectedCity != null && _availableCities.contains(_selectedCity!))
          ? _selectedCity
          : null,
      hint: Text(
        _isLoadingCities
            ? localizations.translate('loading')
            : _selectedCountry != null
            ? localizations.translate('select_city')
            : localizations.translate('first_select_country'),
      ),
      items:
      _availableCities.map((city) {
        return DropdownMenuItem<String>(value: city, child: Text(city));
      }).toList(),
      onChanged:
      (_selectedCountry != null && !_isLoadingCities)
          ? (value) {
        setState(() {
          _selectedCity = value;
        });
      }
          : null,
      disabledHint: Text(
        _selectedCountry == null
            ? localizations.translate('first_select_country')
            : localizations.translate('loading'),
      ),
    );
  }
}