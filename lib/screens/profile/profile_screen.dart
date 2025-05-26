// Путь: lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../repositories/user_repository.dart';
import '../../services/firebase/firebase_service.dart';
import '../../utils/countries_data.dart';
import '../../localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;

  String? _selectedCountry;
  String? _selectedCity;
  List<String> _availableCities = [];
  String? _selectedExperience;
  List<String> _selectedFishingTypes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
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
          _selectedCountry = userData.country;
          _selectedCity = userData.city;
          _selectedExperience = userData.experience;
          _selectedFishingTypes = List<String>.from(userData.fishingTypes);

          // Если страна выбрана, загрузим доступные города
          if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
            _loadCitiesForCountry(_selectedCountry!);
          }
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

  // Загрузка городов для выбранной страны
  void _loadCitiesForCountry(String country) {
    // Получаем города для выбранной страны
    _availableCities = CountriesData.getCitiesForCountry(country);

    // Если ранее выбранного города нет в списке, сбрасываем выбор
    if (_selectedCity != null && !_availableCities.contains(_selectedCity)) {
      _selectedCity = null;
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
      // Обновляем данные пользователя
      final userData = {
        'displayName': _displayNameController.text.trim(),
        'country': _selectedCountry ?? '',
        'city': _selectedCity ?? '',
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: localizations.translate('country'),
                  prefixIcon: const Icon(Icons.public),
                ),
                isExpanded: true,
                value: _selectedCountry,
                hint: Text(localizations.translate('select_country')),
                items: CountriesData.countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedCity = null; // Сбрасываем выбранный город
                      _loadCitiesForCountry(value); // Загружаем города для выбранной страны
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Выпадающий список городов (активен только если выбрана страна)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: localizations.translate('city'),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                isExpanded: true,
                value: _selectedCity,
                hint: Text(localizations.translate('select_city')),
                items: _availableCities.map((city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: _selectedCountry != null
                    ? (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                }
                    : null,
                disabledHint: Text(localizations.translate('first_select_country')),
              ),

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
                  // ИСПРАВЛЕНО: используем ключи локализации напрямую
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
                  // ИСПРАВЛЕНО: используем ключи локализации напрямую
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
}