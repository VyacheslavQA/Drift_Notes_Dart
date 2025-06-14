// Путь: lib/widgets/reminder_selection_widget.dart

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../services/calendar_event_service.dart';

class ReminderSelectionWidget extends StatefulWidget {
  final ReminderType selectedReminder;
  final DateTime? customReminderDateTime;
  final Function(ReminderType, DateTime?) onReminderChanged;
  final bool enabled;
  final DateTime? eventStartDate;

  const ReminderSelectionWidget({
    super.key,
    required this.selectedReminder,
    this.customReminderDateTime,
    required this.onReminderChanged,
    this.enabled = true,
    this.eventStartDate,
  });

  @override
  State<ReminderSelectionWidget> createState() => _ReminderSelectionWidgetState();
}

class _ReminderSelectionWidgetState extends State<ReminderSelectionWidget> {
  late ReminderType _selectedReminder;
  DateTime? _customDateTime;

  @override
  void initState() {
    super.initState();
    _selectedReminder = widget.selectedReminder;
    _customDateTime = widget.customReminderDateTime;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('reminder_settings'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.textColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Без напоминания
              _buildReminderOption(
                reminderType: ReminderType.none,
                localizations: localizations,
              ),

              // Разделитель
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppConstants.textColor.withValues(alpha: 0.1),
              ),

              // Настроить время
              _buildCustomReminderOption(localizations),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderOption({
    required ReminderType reminderType,
    required AppLocalizations localizations,
  }) {
    final isSelected = reminderType == _selectedReminder;

    return InkWell(
      onTap: widget.enabled ? () => _selectReminder(reminderType) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected
                    ? AppConstants.primaryColor
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                Icons.check,
                size: 12,
                color: AppConstants.textColor,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.translate('reminder_none'),
                style: TextStyle(
                  color: isSelected
                      ? AppConstants.textColor
                      : AppConstants.textColor.withValues(alpha: widget.enabled ? 1.0 : 0.5),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.notifications_off,
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.textColor.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReminderOption(AppLocalizations localizations) {
    final isSelected = _selectedReminder == ReminderType.custom;

    return Column(
      children: [
        InkWell(
          onTap: widget.enabled ? () => _selectReminder(ReminderType.custom) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    color: isSelected
                        ? AppConstants.primaryColor
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    size: 12,
                    color: AppConstants.textColor,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('reminder_custom'),
                    style: TextStyle(
                      color: isSelected
                          ? AppConstants.textColor
                          : AppConstants.textColor.withValues(alpha: widget.enabled ? 1.0 : 0.5),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.schedule,
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.textColor.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // Показываем выбор даты и времени только если выбран custom
        if (isSelected) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Выбор даты
                InkWell(
                  onTap: widget.enabled ? _selectDate : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.textColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('select_date'),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _customDateTime != null
                                    ? _formatDate(_customDateTime!, localizations)
                                    : localizations.translate('tap_to_select'),
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Выбор времени
                InkWell(
                  onTap: widget.enabled ? _selectTime : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.textColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('select_time'),
                                style: TextStyle(
                                  color: AppConstants.textColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _customDateTime != null
                                    ? _formatTime(_customDateTime!)
                                    : localizations.translate('tap_to_select'),
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppConstants.textColor.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // Показываем результат если дата и время выбраны
                if (_customDateTime != null && _isValidDateTime()) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${localizations.translate('reminder_will_be_shown')}: ${_getFormattedDateTime(_customDateTime!, localizations)}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_customDateTime != null && !_isValidDateTime()) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations.translate('invalid_reminder_time'),
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _selectReminder(ReminderType reminderType) {
    setState(() {
      _selectedReminder = reminderType;
      if (reminderType != ReminderType.custom) {
        _customDateTime = null;
      }
    });
    widget.onReminderChanged(reminderType, _customDateTime);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final eventStart = widget.eventStartDate ?? now.add(const Duration(days: 7));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _customDateTime?.isBefore(eventStart) == true
          ? _customDateTime!
          : now,
      firstDate: now,
      lastDate: eventStart,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        if (_customDateTime != null) {
          _customDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            _customDateTime!.hour,
            _customDateTime!.minute,
          );
        } else {
          _customDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            12, // По умолчанию 12:00
            0,
          );
        }
      });
      widget.onReminderChanged(_selectedReminder, _customDateTime);
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _customDateTime != null
          ? TimeOfDay.fromDateTime(_customDateTime!)
          : const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.textColor,
              surface: AppConstants.surfaceColor,
              onSurface: AppConstants.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (_customDateTime != null) {
          _customDateTime = DateTime(
            _customDateTime!.year,
            _customDateTime!.month,
            _customDateTime!.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        } else {
          final now = DateTime.now();
          _customDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        }
      });
      widget.onReminderChanged(_selectedReminder, _customDateTime);
    }
  }

  bool _isValidDateTime() {
    if (_customDateTime == null) return false;
    final now = DateTime.now();
    final eventStart = widget.eventStartDate;

    // Проверяем что время в будущем
    if (_customDateTime!.isBefore(now)) return false;

    // Проверяем что время до начала события
    if (eventStart != null && _customDateTime!.isAfter(eventStart)) return false;

    return true;
  }

  // ИСПРАВЛЕНО: Добавлен параметр localizations
  String _formatDate(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return localizations.translate('today'); // ИСПРАВЛЕНО: локализация
    } else if (targetDate == tomorrow) {
      return localizations.translate('tomorrow'); // ИСПРАВЛЕНО: локализация
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ИСПРАВЛЕНО: Добавлен параметр localizations
  String _getFormattedDateTime(DateTime dateTime, AppLocalizations localizations) {
    return '${_formatDate(dateTime, localizations)} ${localizations.translate('at')} ${_formatTime(dateTime)}'; // ИСПРАВЛЕНО: локализация "в"
  }
}

/// Диалог выбора типа напоминания
class ReminderSelectionDialog extends StatefulWidget {
  final ReminderType initialReminder;
  final DateTime? initialCustomDateTime;
  final String title;
  final String description;
  final DateTime? eventStartDate;

  const ReminderSelectionDialog({
    super.key,
    this.initialReminder = ReminderType.none,
    this.initialCustomDateTime,
    required this.title,
    required this.description,
    this.eventStartDate,
  });

  @override
  State<ReminderSelectionDialog> createState() => _ReminderSelectionDialogState();
}

class _ReminderSelectionDialogState extends State<ReminderSelectionDialog> {
  late ReminderType _selectedReminder;
  DateTime? _customDateTime;

  @override
  void initState() {
    super.initState();
    _selectedReminder = widget.initialReminder;
    _customDateTime = widget.initialCustomDateTime;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: ReminderSelectionWidget(
                  selectedReminder: _selectedReminder,
                  customReminderDateTime: _customDateTime,
                  eventStartDate: widget.eventStartDate,
                  onReminderChanged: (reminderType, customDateTime) {
                    setState(() {
                      _selectedReminder = reminderType;
                      _customDateTime = customDateTime;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations.translate('cancel'),
            style: TextStyle(color: AppConstants.textColor),
          ),
        ),
        ElevatedButton(
          onPressed: _canConfirm() ? () => Navigator.pop(context, {
            'reminderType': _selectedReminder,
            'customDateTime': _customDateTime,
          }) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textColor,
          ),
          child: Text(localizations.translate('confirm')),
        ),
      ],
    );
  }

  bool _canConfirm() {
    if (_selectedReminder == ReminderType.none) return true;

    if (_selectedReminder == ReminderType.custom) {
      if (_customDateTime == null) return false;

      final now = DateTime.now();
      if (_customDateTime!.isBefore(now)) return false;

      if (widget.eventStartDate != null && _customDateTime!.isAfter(widget.eventStartDate!)) {
        return false;
      }
    }

    return true;
  }
}

/// Утилитарный класс для показа диалогов напоминаний
class ReminderDialogs {
  /// Показать диалог выбора напоминания для турнира
  static Future<Map<String, dynamic>?> showTournamentReminderDialog(
      BuildContext context, {
        DateTime? eventStartDate,
      }) async {
    final localizations = AppLocalizations.of(context);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReminderSelectionDialog(
        initialReminder: ReminderType.none,
        title: localizations.translate('tournament_reminder_setup'),
        description: localizations.translate('tournament_reminder_setup_desc'),
        eventStartDate: eventStartDate,
      ),
    );
  }

  /// Показать диалог изменения напоминания
  static Future<Map<String, dynamic>?> showEditReminderDialog(
      BuildContext context,
      ReminderType currentReminder,
      String eventTitle, {
        DateTime? currentCustomDateTime,
        DateTime? eventStartDate,
      }) async {
    final localizations = AppLocalizations.of(context);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReminderSelectionDialog(
        initialReminder: currentReminder,
        initialCustomDateTime: currentCustomDateTime,
        title: localizations.translate('edit_reminder'),
        description: localizations.translate('edit_reminder_desc').replaceAll('{event}', eventTitle),
        eventStartDate: eventStartDate,
      ),
    );
  }
}