// Путь: lib/screens/admin/admin_subscription_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/subscription_constants.dart';
import '../../services/admin_service.dart';
import '../../services/firebase/firebase_service.dart';

class AdminSubscriptionScreen extends StatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  State<AdminSubscriptionScreen> createState() => _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState extends State<AdminSubscriptionScreen> {
  final AdminService _adminService = AdminService();
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedDuration = '1 год';
  SubscriptionType _selectedType = SubscriptionType.yearly;
  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.green;

  Map<String, dynamic>? _currentUserInfo;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Проверка доступа админа
  void _checkAdminAccess() {
    final currentUserEmail = _firebaseService.currentUser?.email;
    if (!_adminService.isAdmin(currentUserEmail)) {
      Navigator.of(context).pop();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Управление подписками',
          style: AppConstants.titleStyle,
        ),
        backgroundColor: AppConstants.cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAdminInfo(),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildEmailInput(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildUserInfo(),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildDurationSelector(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildTypeSelector(),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildActionButtons(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildStatusMessage(),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminInfo() {
    final currentUserEmail = _firebaseService.currentUser?.email ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Админская панель',
                  style: AppConstants.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
                Text(
                  'Авторизован: $currentUserEmail',
                  style: AppConstants.captionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email или User ID пользователя',
          style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'example@email.com или User ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchUser,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            helperText: 'Введите email пользователя или скопируйте User ID из Firebase Console',
            helperMaxLines: 2,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите email или User ID пользователя';
            }
            return null;
          },
          onChanged: (value) {
            if (_currentUserInfo != null) {
              setState(() {
                _currentUserInfo = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    if (_currentUserInfo == null) return const SizedBox.shrink();

    final hasSubscription = _currentUserInfo!['hasSubscription'] ?? false;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSubscription ? Icons.person : Icons.person_outline,
                color: hasSubscription ? AppConstants.primaryColor : AppConstants.secondaryTextColor,
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Text(
                  'Информация о пользователе',
                  style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasSubscription ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasSubscription ? 'PREMIUM' : 'FREE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildUserInfoRow('Email', _currentUserInfo!['userEmail']),
          _buildUserInfoRow('User ID', _currentUserInfo!['userId']),

          if (hasSubscription) ...[
            const Divider(),
            _buildUserInfoRow('Статус', _currentUserInfo!['status'] ?? 'unknown'),
            _buildUserInfoRow('Активна', _currentUserInfo!['isActive'] == true ? 'Да' : 'Нет'),
            _buildUserInfoRow('Тип', _currentUserInfo!['type'] ?? 'unknown'),
            if (_currentUserInfo!['expirationDate'] != null)
              _buildUserInfoRow('Истекает', _formatDate(_currentUserInfo!['expirationDate'])),
            _buildUserInfoRow('Платформа', _currentUserInfo!['platform'] ?? 'unknown'),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppConstants.captionStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppConstants.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Срок подписки',
          style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<String>(
          value: _selectedDuration,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            prefixIcon: const Icon(Icons.schedule),
          ),
          items: AdminService.predefinedDurations.keys.map((String duration) {
            return DropdownMenuItem<String>(
              value: duration,
              child: Text(duration),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedDuration = newValue;
                // Автоматически выбираем тип подписки
                if (newValue.contains('год')) {
                  _selectedType = SubscriptionType.yearly;
                } else {
                  _selectedType = SubscriptionType.monthly;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип подписки',
          style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Row(
          children: [
            Expanded(
              child: RadioListTile<SubscriptionType>(
                title: const Text('Месячная'),
                value: SubscriptionType.monthly,
                groupValue: _selectedType,
                onChanged: (SubscriptionType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<SubscriptionType>(
                title: const Text('Годовая'),
                value: SubscriptionType.yearly,
                groupValue: _selectedType,
                onChanged: (SubscriptionType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasSubscription = _currentUserInfo?['hasSubscription'] ?? false;
    final isActive = _currentUserInfo?['isActive'] ?? false;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _grantSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              hasSubscription ? 'Обновить подписку' : 'Выдать подписку',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (hasSubscription && isActive) ...[
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _revokeSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              child: const Text(
                'Отозвать подписку',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _statusColor == Colors.green ? Icons.check_circle : Icons.error,
            color: _statusColor,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              _statusMessage!,
              style: AppConstants.bodyStyle.copyWith(color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: AppConstants.subtitleStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _quickGrant(SubscriptionType.monthly),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Месяц'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _quickGrant(SubscriptionType.yearly),
                icon: const Icon(Icons.calendar_view_month, size: 16),
                label: const Text('Год'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Поиск пользователя
  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _currentUserInfo = null;
    });

    try {
      final input = _emailController.text.trim();
      final userInfo = await _adminService.getUserSubscriptionInfo(input);

      setState(() {
        _currentUserInfo = userInfo;
        if (userInfo == null) {
          _statusMessage = 'Пользователь не найден';
          _statusColor = Colors.orange;
        } else {
          _statusMessage = 'Пользователь найден';
          _statusColor = Colors.green;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка поиска: ${e.toString()}';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Выдача подписки
  Future<void> _grantSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final duration = AdminService.getDurationByName(_selectedDuration);
      if (duration == null) {
        throw Exception('Неверный период подписки');
      }

      await _adminService.grantSubscription(
        userEmailOrId: _emailController.text.trim(),
        subscriptionType: _selectedType,
        duration: duration,
      );

      setState(() {
        _statusMessage = 'Подписка успешно выдана на $_selectedDuration';
        _statusColor = Colors.green;
      });

      // Обновляем информацию о пользователе
      await _searchUser();

    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка выдачи подписки: ${e.toString()}';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Отзыв подписки
  Future<void> _revokeSubscription() async {
    // Подтверждение действия
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите отозвать подписку у пользователя ${_emailController.text.trim()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await _adminService.revokeSubscription(_emailController.text.trim());

      setState(() {
        _statusMessage = 'Подписка успешно отозвана';
        _statusColor = Colors.green;
      });

      // Обновляем информацию о пользователе
      await _searchUser();

    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка отзыва подписки: ${e.toString()}';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Быстрая выдача подписки
  Future<void> _quickGrant(SubscriptionType type) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _selectedType = type;
      _selectedDuration = type == SubscriptionType.yearly ? '1 год' : '1 месяц';
    });

    await _grantSubscription();
  }

  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}