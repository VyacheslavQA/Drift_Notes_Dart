// Путь: lib/services/scheduled_reminder_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';
import '../localization/app_localizations.dart';

class ScheduledReminderService {
  static final ScheduledReminderService _instance = ScheduledReminderService._internal();
  factory ScheduledReminderService() => _instance;
  ScheduledReminderService._internal();

  final NotificationService _notificationService = NotificationService();
  final Map<String, Timer> _activeTimers = {};
  final Map<String, ScheduledReminder> _scheduledReminders = {};

  static const String _scheduledRemindersKey = 'scheduled_reminders_v2';

  BuildContext? _context;
  bool _isInitialized = false;

  /// Установить контекст для локализации
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('⏰ Инициализация сервиса точных напоминаний...');

      await _loadScheduledReminders();
      await _restoreActiveTimers();

      _isInitialized = true;
      debugPrint('✅ Сервис точных напоминаний инициализирован');
      debugPrint('📊 Активных таймеров: ${_activeTimers.length}');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации сервиса точных напоминаний: $e');
    }
  }

  /// Запланировать напоминание на точное время
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String message,
    required DateTime reminderDateTime,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      debugPrint('⏰ Планируем напоминание: $title на ${_formatDateTime(reminderDateTime)}');

      // Проверяем, что время в будущем
      final now = DateTime.now();
      if (reminderDateTime.isBefore(now)) {
        debugPrint('⚠️ Время напоминания в прошлом, пропускаем');
        return;
      }

      // Отменяем существующий таймер если есть
      await cancelReminder(id);

      // Создаем модель напоминания
      final reminder = ScheduledReminder(
        id: id,
        title: title,
        message: message,
        reminderDateTime: reminderDateTime,
        type: type,
        data: data,
        createdAt: now,
      );

      // Сохраняем в память и на диск
      _scheduledReminders[id] = reminder;
      await _saveScheduledReminders();

      // Вычисляем задержку
      final delay = reminderDateTime.difference(now);
      debugPrint('⏰ Задержка до срабатывания: ${delay.inMinutes} минут ${delay.inSeconds % 60} секунд');

      // Создаем таймер
      final timer = Timer(delay, () {
        _triggerReminder(reminder);
      });

      _activeTimers[id] = timer;

      debugPrint('✅ Напоминание запланировано: $title');

    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания: $e');
    }
  }

  /// Отменить запланированное напоминание
  Future<void> cancelReminder(String id) async {
    try {
      // Отменяем таймер
      _activeTimers[id]?.cancel();
      _activeTimers.remove(id);

      // Удаляем из памяти и с диска
      _scheduledReminders.remove(id);
      await _saveScheduledReminders();

      debugPrint('🚫 Напоминание отменено: $id');
    } catch (e) {
      debugPrint('❌ Ошибка отмены напоминания: $e');
    }
  }

  /// Обновить напоминание
  Future<void> updateReminder({
    required String id,
    required String title,
    required String message,
    required DateTime reminderDateTime,
    required NotificationType type,
    Map<String, dynamic> data = const {},
  }) async {
    // Просто отменяем старое и создаем новое
    await cancelReminder(id);
    await scheduleReminder(
      id: id,
      title: title,
      message: message,
      reminderDateTime: reminderDateTime,
      type: type,
      data: data,
    );
  }

  /// Получить все запланированные напоминания
  List<ScheduledReminder> getScheduledReminders() {
    return _scheduledReminders.values.toList();
  }

  /// Получить активные таймеры
  Map<String, Timer> getActiveTimers() {
    return Map.from(_activeTimers);
  }

  /// ИСПРАВЛЕНО: Срабатывание напоминания
  Future<void> _triggerReminder(ScheduledReminder reminder) async {
    try {
      debugPrint('🔔 Срабатывает напоминание: ${reminder.title}');

      // Получаем локализованный заголовок если возможно
      String title = reminder.title;
      if (_context != null && reminder.type == NotificationType.tournamentReminder) {
        try {
          final localizations = AppLocalizations.of(_context!);
          title = localizations.translate('tournament_reminder_title');
        } catch (e) {
          // Используем оригинальный заголовок при ошибке
        }
      }

      // ИСПРАВЛЕНО: Используем специальные методы для разных типов уведомлений
      if (reminder.type == NotificationType.tournamentReminder) {
        await _notificationService.addTournamentReminderNotification(
          id: reminder.id,
          title: title,
          message: reminder.message,
          data: {
            'sourceId': reminder.data['sourceId'] ?? '', // ID турнира для навигации
            'eventId': reminder.data['eventId'] ?? '',
            'eventType': reminder.data['eventType'] ?? '',
            'eventTitle': reminder.data['eventTitle'] ?? reminder.title,
            'location': reminder.data['location'] ?? '',
          },
        );
      } else if (reminder.type == NotificationType.fishingReminder) {
        await _notificationService.addFishingReminderNotification(
          id: reminder.id,
          title: title,
          message: reminder.message,
          data: {
            'sourceId': reminder.data['sourceId'] ?? '', // ID заметки для навигации
            'eventId': reminder.data['eventId'] ?? '',
            'eventType': reminder.data['eventType'] ?? '',
            'eventTitle': reminder.data['eventTitle'] ?? reminder.title,
            'location': reminder.data['location'] ?? '',
          },
        );
      } else {
        // Для других типов используем общий метод
        await _notificationService.createNotification(
          title: title,
          message: reminder.message,
          type: reminder.type,
          data: reminder.data,
        );
      }

      // Удаляем из активных напоминаний
      _activeTimers.remove(reminder.id);
      _scheduledReminders.remove(reminder.id);
      await _saveScheduledReminders();

      debugPrint('✅ Уведомление отправлено и напоминание удалено: ${reminder.title}');

    } catch (e) {
      debugPrint('❌ Ошибка срабатывания напоминания: $e');
    }
  }

  /// Загрузить сохраненные напоминания
  Future<void> _loadScheduledReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList(_scheduledRemindersKey) ?? [];

      _scheduledReminders.clear();

      final now = DateTime.now();
      bool hasExpiredReminders = false;

      for (final reminderJson in remindersJson) {
        try {
          final reminderMap = json.decode(reminderJson);
          final reminder = ScheduledReminder.fromJson(reminderMap);

          // Проверяем, не истекло ли время
          if (reminder.reminderDateTime.isAfter(now)) {
            _scheduledReminders[reminder.id] = reminder;
          } else {
            hasExpiredReminders = true;
            debugPrint('⏰ Пропущенное напоминание удалено: ${reminder.title}');
          }
        } catch (e) {
          debugPrint('❌ Ошибка парсинга напоминания: $e');
        }
      }

      // Если были истекшие напоминания, сохраняем обновленный список
      if (hasExpiredReminders) {
        await _saveScheduledReminders();
      }

      debugPrint('📂 Загружено напоминаний: ${_scheduledReminders.length}');

    } catch (e) {
      debugPrint('❌ Ошибка загрузки напоминаний: $e');
    }
  }

  /// Восстановить активные таймеры после перезапуска приложения
  Future<void> _restoreActiveTimers() async {
    try {
      final now = DateTime.now();

      for (final reminder in _scheduledReminders.values) {
        if (reminder.reminderDateTime.isAfter(now)) {
          final delay = reminder.reminderDateTime.difference(now);

          debugPrint('🔄 Восстанавливаем таймер для: ${reminder.title}');
          debugPrint('⏰ Времени до срабатывания: ${delay.inMinutes} минут');

          final timer = Timer(delay, () {
            _triggerReminder(reminder);
          });

          _activeTimers[reminder.id] = timer;
        }
      }

      debugPrint('🔄 Восстановлено таймеров: ${_activeTimers.length}');

    } catch (e) {
      debugPrint('❌ Ошибка восстановления таймеров: $e');
    }
  }

  /// Сохранить напоминания
  Future<void> _saveScheduledReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _scheduledReminders.values
          .map((reminder) => json.encode(reminder.toJson()))
          .toList();

      await prefs.setStringList(_scheduledRemindersKey, remindersJson);
    } catch (e) {
      debugPrint('❌ Ошибка сохранения напоминаний: $e');
    }
  }

  /// Очистить все напоминания
  Future<void> clearAllReminders() async {
    try {
      // Отменяем все таймеры
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();

      // Очищаем память и диск
      _scheduledReminders.clear();
      await _saveScheduledReminders();

      debugPrint('🧹 Все напоминания очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки напоминаний: $e');
    }
  }

  /// Получить статистику
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final activeCount = _scheduledReminders.values
        .where((r) => r.reminderDateTime.isAfter(now))
        .length;

    return {
      'totalScheduled': _scheduledReminders.length,
      'activeTimers': _activeTimers.length,
      'activeReminders': activeCount,
      'isInitialized': _isInitialized,
    };
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Освобождение ресурсов
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    debugPrint('🧹 ScheduledReminderService: ресурсы освобождены');
  }
}

/// Модель запланированного напоминания
class ScheduledReminder {
  final String id;
  final String title;
  final String message;
  final DateTime reminderDateTime;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  ScheduledReminder({
    required this.id,
    required this.title,
    required this.message,
    required this.reminderDateTime,
    required this.type,
    this.data = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'reminderDateTime': reminderDateTime.millisecondsSinceEpoch,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) {
    return ScheduledReminder(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      reminderDateTime: DateTime.fromMillisecondsSinceEpoch(json['reminderDateTime'] ?? 0),
      type: NotificationType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}