// Путь: lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../repositories/user_repository.dart';
import '../../services/firebase/firebase_service.dart';
import '../../services/geography_service.dart';
import '../../localization/app_localizations.dart';

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

  // Добавляем переменные для сохранения ключей
  String? _selectedCountryKey;
  String? _selectedCityKey;

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
      _loadCountries();
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCountries = true;
    });

    try {
      final countries = await _geographyService.getLocalizedCountries(context);
      if (mounted) {
        setState(() {
          _availableCountries = countries;
          _isLoadingCountries = false;
        });

        // После загрузки стран проверяем сохраненную страну
        await _updateSelectedCountryFromSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
        debugPrint('❌ Ошибка загрузки стран: $e');
      }
    }
  }

  Future<void> _updateSelectedCountryFromSaved() async {
    if (_selectedCountryKey != null && _availableCountries.isNotEmpty) {
      try {
        // Пытаемся найти страну по ключу
        final countryName = await _geographyService.getCountryNameByKey(_selectedCountryKey!, context);
        if (countryName != null && _availableCountries.contains(countryName)) {
          setState(() {
            _selectedCountry = countryName;
          });
          // Загружаем города для выбранной страны
          await _loadCitiesForCountry(countryName);
        } else {
          // Если не нашли по ключу, пытаемся найти в списке как есть
          if (_availableCountries.contains(_selectedCountryKey)) {
            setState(() {
              _selectedCountry = _selectedCountryKey;
            });
            await _loadCitiesForCountry(_selectedCountryKey!);
          } else {
            debugPrint('🚫 Сохраненная страна "$_selectedCountryKey" не найдена в списке доступных стран');
            setState(() {
              _selectedCountry = null;
              _selectedCountryKey = null;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ Ошибка при обновлении выбранной страны: $e');
        setState(() {
          _selectedCountry = null;
          _selectedCountryKey = null;
        });
      }
    }
  }

  Future<void> _loadCitiesForCountry(String country) async {
    if (!mounted) return;

    setState(() {
      _isLoadingCities = true;
      _availableCities = [];
      _selectedCity = null;
    });

    try {
      final cities = await _geographyService.getLocalizedCitiesForCountry(country, context);
      if (mounted) {
        setState(() {
          _availableCities = cities;
          _isLoadingCities = false;
        });

        // После загрузки городов проверяем сохраненный город
        await _updateSelectedCityFromSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
        debugPrint('❌ Ошибка загрузки городов для $country: $e');
      }
    }
  }

  Future<void> _updateSelectedCityFromSaved() async {
    if (_selectedCityKey != null && _availableCities.isNotEmpty && _selectedCountry != null) {
      try {
        // Пытаемся найти город по ключу
        final cityName = await _geographyService.getCityNameByKey(
            _selectedCityKey!,
            _selectedCountry!,
            context
        );
        if (cityName != null && _availableCities.contains(cityName)) {
          setState(() {
            _selectedCity = cityName;
          });
        } else {
          // Если не нашли по ключу, пытаемся найти в списке как есть
          if (_availableCities.contains(_selectedCityKey)) {
            setState(() {
              _selectedCity = _selectedCityKey;
            });
          } else {
            debugPrint('🚫 Сохраненный город "$_selectedCityKey" не найден в списке доступных городов');
            setState(() {
              _selectedCity = null;
              _selectedCityKey = null;
            });
          }
        }
      } catch (e) {
        debugPrint('❌ Ошибка при обновлении выбранного города: $e');
        setState(() {
          _selectedCity = null;
          _selectedCityKey = null;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _userRepository.getCurrentUserData();

      if (userData != null) {
        setState(() {
          _displayNameController.text = userData.displayName ?? '';
          _emailController.text = userData.email;
          _selectedExperience = userData.experience;
          _selectedFishingTypes = List<String>.from(userData.fishingTypes);

          // Сохраняем ключи из базы данных
          _selectedCountryKey = userData.country;
          _selectedCityKey = userData.city;
        });
      } else {
        // Если нет данных в Firestore, используем данные из FirebaseAuth
        final user = _firebaseService.currentUser;
        if (user != null) {
          setState(() {
            _displayNameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('error_loading')}: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Получаем ключи стран и городов для сохранения
      String? countryKey;
      String? cityKey;

      if (_selectedCountry != null) {
        countryKey = await _geographyService.getCountryKeyByName(_selectedCountry!, context);
        // Если не нашли ключ, используем название как есть
        countryKey ??= _selectedCountry;
      }

      if (_selectedCity != null && _selectedCountry != null) {
        cityKey = await _geographyService.getCityKeyByName(
            _selectedCity!,
            _selectedCountry!,
            context
        );
        // Если не нашли ключ, используем название как есть
        cityKey ??= _selectedCity;
      }

      // Обновляем данные пользователя
      final userData = {
        'displayName': _displayNameController.text.trim(),
        'country': countryKey ?? '',
        'city': cityKey ?? '',
        'experience': _selectedExperience,
        'fishingTypes': _selectedFishingTypes,
      };

      await _userRepository.updateUserData(userData);

      // Обновляем имя пользователя в FirebaseAuth
      final user = _firebaseService.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
      }

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('profile_updated_successfully')),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.translate('profile_update_error')}: $e')),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppConstants.textColor))
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
                children: AppConstants.experienceLevels.map((levelKey) {
                  String translatedLevel = localizations.translate(levelKey);

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
                      color: _selectedExperience == levelKey
                          ? AppConstants.textColor
                          : AppConstants.textColor.withValues(alpha: 0.7),
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
                children: AppConstants.fishingTypes.map((typeKey) {
                  String translatedType = localizations.translate(typeKey);

                  return FilterChip(
                    label: Text(translatedType),
                    selected: _selectedFishingTypes.contains(typeKey),
                    onSelected: (_) => _toggleFishingType(typeKey),
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedFishingTypes.contains(typeKey)
                          ? AppConstants.textColor
                          : AppConstants.textColor.withValues(alpha: 0.7),
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
                  child: _isSaving
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

              const SizedBox(height: 24),
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
        suffixIcon: _isLoadingCountries
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
      // ИСПРАВЛЕНИЕ: Проверяем, что выбранная страна есть в списке
      value: (_selectedCountry != null && _availableCountries.contains(_selectedCountry!))
          ? _selectedCountry
          : null,
      hint: Text(
          _isLoadingCountries
              ? localizations.translate('loading')
              : localizations.translate('select_country')
      ),
      items: _availableCountries.map((country) {
        return DropdownMenuItem<String>(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: _isLoadingCountries ? null : (value) {
        if (value != null) {
          setState(() {
            _selectedCountry = value;
            _selectedCity = null;
            _selectedCityKey = null;
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
        suffixIcon: _isLoadingCities
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
      // ИСПРАВЛЕНИЕ: Проверяем, что выбранный город есть в списке
      value: (_selectedCity != null && _availableCities.contains(_selectedCity!))
          ? _selectedCity
          : null,
      hint: Text(
          _isLoadingCities
              ? localizations.translate('loading')
              : _selectedCountry != null
              ? localizations.translate('select_city')
              : localizations.translate('first_select_country')
      ),
      items: _availableCities.map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: (_selectedCountry != null && !_isLoadingCities)
          ? (value) {
        setState(() {
          _selectedCity = value;
        });
      }
          : null,
      disabledHint: Text(
          _selectedCountry == null
              ? localizations.translate('first_select_country')
              : localizations.translate('loading')
      ),
    );
  }
}