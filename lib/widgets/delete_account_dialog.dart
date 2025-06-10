// Путь: lib/widgets/delete_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _confirmationController = TextEditingController();
  bool _isDeleteButtonEnabled = false;
  String _currentKeyboard = 'unknown';

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_onTextChanged);
    _detectKeyboardLayout();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  // Определение текущей раскладки клавиатуры
  void _detectKeyboardLayout() {
    // Простое определение раскладки по системной локали
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    if (locale.languageCode == 'ru') {
      _currentKeyboard = 'ru';
    } else {
      _currentKeyboard = 'en';
    }
  }

  void _onTextChanged() {
    final text = _confirmationController.text.toLowerCase().trim();
    bool isValid = false;

    // Проверяем оба варианта независимо от раскладки
    if (text == 'удалить' || text == 'delete') {
      isValid = true;
    }

    setState(() {
      _isDeleteButtonEnabled = isValid;
    });
  }

  String _getRequiredWord() {
    return _currentKeyboard == 'ru' ? 'удалить' : 'delete';
  }

  String _getConfirmationText(AppLocalizations localizations) {
    if (_currentKeyboard == 'ru') {
      return 'Для подтверждения удаления аккаунта введите слово "удалить" в поле ниже:';
    } else {
      return 'To confirm account deletion, type the word "delete" in the field below:';
    }
  }

  String _getHintText() {
    return _currentKeyboard == 'ru'
        ? 'Введите "удалить" для подтверждения'
        : 'Type "delete" to confirm';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.translate('delete_account_warning'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Предупреждающий текст
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('delete_account_warning_text'),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.translate('this_action_cannot_be_undone'),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Инструкция по подтверждению
              Text(
                _getConfirmationText(localizations),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              // Информация о текущей раскладке
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.keyboard,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentKeyboard == 'ru'
                            ? 'Текущая раскладка: Русская (введите "удалить")'
                            : 'Current layout: English (type "delete")',
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Поле ввода подтверждения
              Container(
                width: double.infinity,
                child: TextField(
                  controller: _confirmationController,
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    hintStyle: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppConstants.textColor.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isDeleteButtonEnabled ? Colors.red : AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      _isDeleteButtonEnabled ? Icons.check_circle : Icons.edit,
                      color: _isDeleteButtonEnabled ? Colors.green : AppConstants.textColor.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.text,
                ),
              ),

              const SizedBox(height: 12),

              // Статус валидации
              if (_confirmationController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDeleteButtonEnabled
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDeleteButtonEnabled ? Icons.check_circle : Icons.error,
                        color: _isDeleteButtonEnabled ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isDeleteButtonEnabled
                              ? 'Подтверждение принято'
                              : 'Введите "${_getRequiredWord()}" для подтверждения',
                          style: TextStyle(
                            color: _isDeleteButtonEnabled ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  localizations.translate('cancel'),
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isDeleteButtonEnabled
                    ? () {
                  // Добавляем тактильную обратную связь
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop(true);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDeleteButtonEnabled ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  localizations.translate('delete_account'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}