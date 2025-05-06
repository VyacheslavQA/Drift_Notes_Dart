// Путь: lib/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../services/firebase/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;

  String? _selectedExperience;
  List<String> _selectedFishingTypes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _countryController = TextEditingController();
    _cityController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _cityController.dispose();
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
          _countryController.text = userData.country ?? '';
          _cityController.text = userData.city ?? '';
          _selectedExperience = userData.experience;
          _selectedFishingTypes = List<String>.from(userData.fishingTypes);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке данных: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedAvatar = File(pickedFile.path);
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
      String? avatarUrl;

      // Если выбран новый аватар, загружаем его
      if (_selectedAvatar != null) {
        final userId = _userRepository.currentUserId;
        if (userId != null) {
          final bytes = await _selectedAvatar!.readAsBytes();
          final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final path = 'users/$userId/avatar/$fileName';

          avatarUrl = await _firebaseService.uploadImage(path, bytes);
        }
      }

      // Обновляем данные пользователя
      final userData = {
        'displayName': _displayNameController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'experience': _selectedExperience,
        'fishingTypes': _selectedFishingTypes,
      };

      if (avatarUrl != null) {
        userData['avatarUrl'] = avatarUrl;
      }

      await _userRepository.updateUserData(userData);

      // Обновляем имя пользователя в FirebaseAuth
      final user = _firebaseService.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении профиля: $e')),
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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Личный кабинет'),
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
              // Аватар пользователя
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppConstants.surfaceColor,
                        backgroundImage: _selectedAvatar != null
                            ? FileImage(_selectedAvatar!) as ImageProvider
                            : const AssetImage('assets/images/default_avatar.png'),
                        child: _selectedAvatar == null
                            ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppConstants.textColor,
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppConstants.textColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Имя пользователя
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите ваше имя';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email (не редактируемый)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              // Страна
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Страна',
                  prefixIcon: Icon(Icons.public),
                ),
              ),

              const SizedBox(height: 16),

              // Город
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),

              const SizedBox(height: 24),

              // Уровень опыта
              Text(
                'Уровень опыта',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: AppConstants.experienceLevels.map((level) {
                  return ChoiceChip(
                    label: Text(level),
                    selected: _selectedExperience == level,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedExperience = level;
                        });
                      }
                    },
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedExperience == level
                          ? AppConstants.textColor
                          : AppConstants.textColor.withOpacity(0.7),
                    ),
                    backgroundColor: AppConstants.surfaceColor,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Типы рыбалки
              Text(
                'Предпочитаемые типы рыбалки',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: AppConstants.fishingTypes.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: _selectedFishingTypes.contains(type),
                    onSelected: (_) => _toggleFishingType(type),
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedFishingTypes.contains(type)
                          ? AppConstants.textColor
                          : AppConstants.textColor.withOpacity(0.7),
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
                    'СОХРАНИТЬ',
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