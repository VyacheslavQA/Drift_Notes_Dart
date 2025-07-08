// lib/screens/debug/simple_migration_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/firebase/simplified_migration_tool.dart';
import '../../services/firebase/firebase_service.dart';
import '../../constants/app_constants.dart';

class SimpleMigrationPage extends StatefulWidget {
  @override
  _SimpleMigrationPageState createState() => _SimpleMigrationPageState();
}

class _SimpleMigrationPageState extends State<SimpleMigrationPage> {
  final SimplifiedMigrationTool _migrationTool = SimplifiedMigrationTool();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  String _statusMessage = '';
  String _quickStatus = '';
  Map<String, dynamic>? _verificationResult;

  @override
  void initState() {
    super.initState();
    _checkQuickStatus();
  }

  Future<void> _checkQuickStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _showMessage('🔍 Проверяем статус...');

      final status = await _migrationTool.getQuickStatus();
      setState(() {
        _quickStatus = status;
        _statusMessage = '✅ Статус обновлен';
      });

      if (kDebugMode) {
        debugPrint('Статус обновлен: $status');
      }

    } catch (e) {
      setState(() {
        _quickStatus = '❌ Ошибка проверки: $e';
      });

      _showError('Ошибка проверки статуса: $e');

      if (kDebugMode) {
        debugPrint('Ошибка _checkQuickStatus: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });

    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _showSuccess(String message) {
    setState(() {
      _statusMessage = '✅ $message';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String error) {
    setState(() {
      _statusMessage = '❌ $error';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _runFullMigration() async {
    if (_isLoading) return;

    // Показываем предупреждение
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Подтверждение миграции',
          style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Будет выполнена полная миграция данных в новую структуру:',
              style: TextStyle(color: AppConstants.textColor),
            ),
            SizedBox(height: 8),
            Text(
              '• fishing_notes → users/{userId}/fishing_notes/',
              style: TextStyle(color: AppConstants.textColor, fontSize: 12),
            ),
            Text(
              '• fishing_trips → users/{userId}/fishing_trips/',
              style: TextStyle(color: AppConstants.textColor, fontSize: 12),
            ),
            Text(
              '• marker_maps → users/{userId}/marker_maps/',
              style: TextStyle(color: AppConstants.textColor, fontSize: 12),
            ),
            Text(
              '• user_consents → users/{userId}/user_consents/',
              style: TextStyle(color: AppConstants.textColor, fontSize: 12),
            ),
            SizedBox(height: 8),
            Text(
              '• usage_limits будет удален (не критично)',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              'Это займет несколько минут. Продолжить?',
              style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена', style: TextStyle(color: AppConstants.textColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: Text('Запустить миграцию', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _showMessage('🚀 Запускаем полную миграцию...');

      final result = await _migrationTool.runCompleteMigration();

      setState(() {
        _verificationResult = result;
      });

      _showSuccess('Полная миграция завершена успешно!');
      await _checkQuickStatus();

    } catch (e) {
      _showError('Ошибка полной миграции: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupOldData() async {
    if (_isLoading) return;

    // Показываем строгое предупреждение
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'ОПАСНАЯ ОПЕРАЦИЯ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Будут НАВСЕГДА удалены все старые коллекции:',
              style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• fishing_notes\n• fishing_trips\n• marker_maps\n• user_consents',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 12),
            Text(
              'УБЕДИТЕСЬ, что миграция прошла успешно!\nЭто действие НЕОБРАТИМО!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена', style: TextStyle(color: AppConstants.textColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('УДАЛИТЬ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _showMessage('🗑️ Удаляем старые данные...');

      await _migrationTool.cleanupOldData();

      _showSuccess('Старые данные удалены!');
      await _checkQuickStatus();

    } catch (e) {
      _showError('Ошибка удаления: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _showMessage('👤 Создаем тестовый профиль...');

      await _migrationTool.createTestProfile();

      _showSuccess('Тестовый профиль создан!');
      await _checkQuickStatus();

    } catch (e) {
      _showError('Ошибка создания профиля: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildVerificationResults() {
    if (_verificationResult == null) return SizedBox.shrink();

    final newData = _verificationResult!['newStructure'] as Map<String, dynamic>;
    final oldData = _verificationResult!['oldStructure'] as Map<String, dynamic>;

    return Card(
      color: AppConstants.surfaceColor,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Результаты миграции:',
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            Text(
              'Новая структура (users/{userId}/...):',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            _buildDataRow('📝 Записи о рыбалке', newData['notes']),
            _buildDataRow('🎣 Поездки', newData['trips']),
            _buildDataRow('🗺️ Карты', newData['maps']),
            _buildDataRow('✅ Согласия', newData['consents']),

            SizedBox(height: 16),

            Text(
              'Старая структура (нужно удалить):',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            _buildDataRow('📝 fishing_notes', oldData['notes'], isOld: true),
            _buildDataRow('🎣 fishing_trips', oldData['trips'], isOld: true),
            _buildDataRow('🗺️ marker_maps', oldData['maps'], isOld: true),
            _buildDataRow('✅ user_consents', oldData['consents'], isOld: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value, {bool isOld = false}) {
    final color = isOld && value > 0 ? Colors.orange : AppConstants.textColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Миграция в структуру "по полочкам"',
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: AppConstants.surfaceColor,
        iconTheme: IconThemeData(color: AppConstants.textColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информация о пользователе
            Card(
              color: AppConstants.surfaceColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 Текущий пользователь:',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _firebaseService.currentUserId ?? 'Не авторизован',
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                    if (_firebaseService.currentUser?.email != null) ...[
                      SizedBox(height: 4),
                      Text(
                        _firebaseService.currentUser!.email!,
                        style: TextStyle(color: AppConstants.textColor.withOpacity(0.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Быстрый статус
            Card(
              color: AppConstants.surfaceColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Текущий статус:',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _quickStatus,
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkQuickStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: _isLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Проверяю...', style: TextStyle(color: Colors.white)),
                              ],
                            )
                                : Text(
                              'Обновить статус',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Статус операции
            if (_statusMessage.isNotEmpty)
              Card(
                color: AppConstants.surfaceColor,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('❌')
                          ? Colors.red
                          : _statusMessage.startsWith('✅')
                          ? Colors.green
                          : AppConstants.textColor,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Кнопки действий
            ElevatedButton(
              onPressed: _isLoading ? null : _createTestProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '👤 Создать тестовый профиль',
                style: TextStyle(color: AppConstants.textColor),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _runFullMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '🚀 ПОЛНАЯ МИГРАЦИЯ В SUBCOLLECTIONS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _cleanupOldData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '🗑️ УДАЛИТЬ СТАРЫЕ ДАННЫЕ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),

            // Индикатор загрузки
            if (_isLoading) ...[
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppConstants.primaryColor),
                    SizedBox(height: 8),
                    Text(
                      'Выполняется операция...',
                      style: TextStyle(color: AppConstants.textColor),
                    ),
                  ],
                ),
              ),
            ],

            // Результаты проверки
            _buildVerificationResults(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}