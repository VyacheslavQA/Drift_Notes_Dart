// Путь: lib/services/calendar_event_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tournament_model.dart';
import 'scheduled_reminder_service.dart';
import '../models/notification_model.dart';

class CalendarEventService {
  static final CalendarEventService _instance = CalendarEventService._internal();
  factory CalendarEventService() => _instance;
  CalendarEventService._internal();

  static const String _calendarEventsKey = 'calendar_events';

  // Интеграция с сервисом точных напоминаний
  final ScheduledReminderService _scheduledReminderService = ScheduledReminderService();

  /// Добавить турнир в календарь
  Future<void> addTournamentToCalendar({
    required TournamentModel tournament,
    required ReminderType reminderType,
    DateTime? customReminderDateTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await getCalendarEvents();

      // Создаем событие календаря
      final event = CalendarEvent(
        id: 'tournament_${tournament.id}',
        title: tournament.name,
        startDate: tournament.startDate,
        endDate: tournament.endDate ?? tournament.startDate.add(Duration(hours: tournament.duration)),
        location: tournament.location,
        description: 'Организатор: ${tournament.organizer}\nТип рыбалки: ${tournament.fishingType.displayName}\nКатегория: ${tournament.category.displayName}',
        type: CalendarEventType.tournament,
        reminderType: reminderType,
        customReminderDateTime: customReminderDateTime,
        sourceId: tournament.id,
      );

      // Удаляем существующее событие, если есть
      events.removeWhere((e) => e.id == event.id);

      // Добавляем новое событие
      events.add(event);

      // Сохраняем
      await _saveCalendarEvents(events);

      // НОВОЕ: Планируем точное напоминание
      await _scheduleEventReminder(event);

      debugPrint('Турнир ${tournament.name} добавлен в календарь');
    } catch (e) {
      debugPrint('Ошибка при добавлении турнира в календарь: $e');
      rethrow;
    }
  }

  /// Добавить заметку о рыбалке в календарь
  Future<void> addFishingNoteToCalendar({
    required String noteId,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    required ReminderType reminderType,
    DateTime? customReminderDateTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await getCalendarEvents();

      // Создаем событие календаря для рыбалки
      final event = CalendarEvent(
        id: 'fishing_note_$noteId',
        title: title,
        startDate: startDate,
        endDate: endDate ?? startDate.add(const Duration(hours: 8)), // по умолчанию 8 часов
        location: location,
        description: 'Запланированная рыбалка',
        type: CalendarEventType.fishing,
        reminderType: reminderType,
        customReminderDateTime: customReminderDateTime,
        sourceId: noteId,
      );

      // Удаляем существующее событие, если есть
      events.removeWhere((e) => e.id == event.id);

      // Добавляем новое событие
      events.add(event);

      // Сохраняем
      await _saveCalendarEvents(events);

      // НОВОЕ: Планируем точное напоминание
      await _scheduleEventReminder(event);

      debugPrint('Рыбалка $title добавлена в календарь');
    } catch (e) {
      debugPrint('Ошибка при добавлении рыбалки в календарь: $e');
      rethrow;
    }
  }

  /// Получить все события календаря
  Future<List<CalendarEvent>> getCalendarEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_calendarEventsKey) ?? [];

      final events = <CalendarEvent>[];
      for (final eventJson in eventsJson) {
        try {
          final eventMap = jsonDecode(eventJson) as Map<String, dynamic>;
          events.add(CalendarEvent.fromJson(eventMap));
        } catch (e) {
          debugPrint('Ошибка при декодировании события: $e');
        }
      }

      return events;
    } catch (e) {
      debugPrint('Ошибка при получении событий календаря: $e');
      return [];
    }
  }

  /// Получить события за определенную дату
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final allEvents = await getCalendarEvents();
    final targetDate = DateTime(date.year, date.month, date.day);

    return allEvents.where((event) {
      final eventStartDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final eventEndDate = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );

      return targetDate.isAtSameMomentAs(eventStartDate) ||
          targetDate.isAtSameMomentAs(eventEndDate) ||
          (targetDate.isAfter(eventStartDate) && targetDate.isBefore(eventEndDate));
    }).toList();
  }

  /// Получить события, для которых нужно показать напоминания
  Future<List<CalendarEvent>> getEventsForReminders() async {
    final allEvents = await getCalendarEvents();
    final now = DateTime.now();

    return allEvents.where((event) => event.shouldShowReminder()).toList();
  }

  /// Удалить событие
  Future<void> removeEvent(String eventId) async {
    try {
      final events = await getCalendarEvents();

      // Находим событие для отмены напоминания
      final eventToRemove = events.firstWhere(
              (e) => e.id == eventId,
          orElse: () => throw Exception('Event not found')
      );

      events.removeWhere((e) => e.id == eventId);
      await _saveCalendarEvents(events);

      // НОВОЕ: Отменяем запланированное напоминание
      await _cancelEventReminder(eventToRemove);

      debugPrint('Событие $eventId удалено из календаря');
    } catch (e) {
      debugPrint('Ошибка при удалении события: $e');
      rethrow;
    }
  }

  /// Проверить, добавлен ли турнир в календарь
  Future<bool> isTournamentInCalendar(String tournamentId) async {
    final events = await getCalendarEvents();
    return events.any((e) => e.sourceId == tournamentId && e.type == CalendarEventType.tournament);
  }

  /// Проверить, добавлена ли заметка о рыбалке в календарь
  Future<bool> isFishingNoteInCalendar(String noteId) async {
    final events = await getCalendarEvents();
    return events.any((e) => e.sourceId == noteId && e.type == CalendarEventType.fishing);
  }

  /// Обновить напоминание для события
  Future<void> updateEventReminder(String eventId, ReminderType newReminderType, {DateTime? customReminderDateTime}) async {
    try {
      final events = await getCalendarEvents();
      final eventIndex = events.indexWhere((e) => e.id == eventId);

      if (eventIndex != -1) {
        final oldEvent = events[eventIndex]; // ИСПРАВЛЕНО: объявляем переменную
        final updatedEvent = CalendarEvent(
          id: oldEvent.id,
          title: oldEvent.title,
          startDate: oldEvent.startDate,
          endDate: oldEvent.endDate,
          location: oldEvent.location,
          description: oldEvent.description,
          type: oldEvent.type,
          reminderType: newReminderType,
          customReminderDateTime: customReminderDateTime,
          sourceId: oldEvent.sourceId,
        );

        events[eventIndex] = updatedEvent;
        await _saveCalendarEvents(events);

        // ИСПРАВЛЕНО: вызываем метод с другим именем
        await _updateEventReminderSchedule(oldEvent, updatedEvent);

        debugPrint('Напоминание для события $eventId обновлено');
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении напоминания: $e');
      rethrow;
    }
  }

  /// Сохранить события в SharedPreferences
  Future<void> _saveCalendarEvents(List<CalendarEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = events.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_calendarEventsKey, eventsJson);
    } catch (e) {
      debugPrint('Ошибка при сохранении событий: $e');
      rethrow;
    }
  }

  /// Очистить все события
  Future<void> clearAllEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_calendarEventsKey);
      debugPrint('Все события календаря удалены');
    } catch (e) {
      debugPrint('Ошибка при очистке событий: $e');
      rethrow;
    }
  }

  /// ИСПРАВЛЕНО: Запланировать напоминание для события
  Future<void> _scheduleEventReminder(CalendarEvent event) async {
    try {
      final reminderTime = event.calculateReminderTime();

      if (reminderTime == null || reminderTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Время напоминания не установлено или в прошлом');
        return;
      }

      // Определяем тип уведомления
      final notificationType = event.type == CalendarEventType.tournament
          ? NotificationType.tournamentReminder
          : NotificationType.fishingReminder;

      // Создаем сообщение
      String title, message;
      if (event.type == CalendarEventType.tournament) {
        title = 'Напоминание о турнире';
        message = '${event.title} начнется ${_formatEventTime(event.startDate)}';
      } else {
        title = 'Напоминание о рыбалке';
        message = '${event.title} запланирована на ${_formatEventTime(event.startDate)}';
      }

      if (event.location != null && event.location!.isNotEmpty) {
        message += '\nМесто: ${event.location}';
      }

      debugPrint('🔍 Планируем напоминание для турнира:');
      debugPrint('  - Event ID: ${event.id}');
      debugPrint('  - Source ID (Tournament ID): ${event.sourceId}');
      debugPrint('  - Title: ${event.title}');

      // ИСПРАВЛЕНО: Планируем точное напоминание с правильными данными
      await _scheduledReminderService.scheduleReminder(
        id: event.id,
        title: title,
        message: message,
        reminderDateTime: reminderTime,
        type: notificationType,
        data: {
          'sourceId': event.sourceId ?? '', // Чистый ID турнира (например, jun_1)
          'eventId': event.id, // ID события календаря (например, tournament_jun_1)
          'eventType': event.type.toString(),
          'eventTitle': event.title,
          'location': event.location ?? '',
        },
      );

      debugPrint('✅ Точное напоминание запланировано для: ${event.title}');
      debugPrint('✅ С данными: sourceId=${event.sourceId}, eventId=${event.id}');

    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания: $e');
    }
  }

  /// НОВЫЙ: Отменить напоминание для события
  Future<void> _cancelEventReminder(CalendarEvent event) async {
    try {
      await _scheduledReminderService.cancelReminder(event.id);
      debugPrint('🚫 Напоминание отменено для: ${event.title}');
    } catch (e) {
      debugPrint('❌ Ошибка отмены напоминания: $e');
    }
  }

  /// НОВЫЙ: Обновить напоминание для события
  Future<void> _updateEventReminderSchedule(CalendarEvent oldEvent, CalendarEvent newEvent) async {
    try {
      await _cancelEventReminder(oldEvent);
      await _scheduleEventReminder(newEvent);
      debugPrint('🔄 Напоминание обновлено для: ${newEvent.title}');
    } catch (e) {
      debugPrint('❌ Ошибка обновления напоминания: $e');
    }
  }

  /// НОВЫЙ: Форматирование времени события
  String _formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (eventDate == today) {
      dateStr = 'сегодня';
    } else if (eventDate == tomorrow) {
      dateStr = 'завтра';
    } else {
      dateStr = '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dateStr в $timeStr';
  }
}

/// Модель события календаря
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String? description;
  final CalendarEventType type;
  final ReminderType reminderType;
  final DateTime? customReminderDateTime;
  final String? sourceId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.location,
    this.description,
    required this.type,
    required this.reminderType,
    this.customReminderDateTime,
    this.sourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'location': location,
      'description': description,
      'type': type.toString(),
      'reminderType': reminderType.toString(),
      'customReminderDateTime': customReminderDateTime?.millisecondsSinceEpoch,
      'sourceId': sourceId,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
      location: json['location'] as String?,
      description: json['description'] as String?,
      type: _parseEventType(json['type'] as String),
      reminderType: _parseReminderType(json['reminderType'] as String),
      customReminderDateTime: json['customReminderDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['customReminderDateTime'] as int)
          : null,
      sourceId: json['sourceId'] as String?,
    );
  }

  static CalendarEventType _parseEventType(String typeStr) {
    switch (typeStr) {
      case 'CalendarEventType.tournament':
        return CalendarEventType.tournament;
      case 'CalendarEventType.fishing':
        return CalendarEventType.fishing;
      default:
        return CalendarEventType.fishing;
    }
  }

  static ReminderType _parseReminderType(String reminderStr) {
    switch (reminderStr) {
      case 'ReminderType.none':
        return ReminderType.none;
      case 'ReminderType.custom':
        return ReminderType.custom;
      default:
        return ReminderType.none;
    }
  }

  /// Вычислить время напоминания
  DateTime? calculateReminderTime() {
    switch (reminderType) {
      case ReminderType.none:
        return null;
      case ReminderType.custom:
        return customReminderDateTime;
    }
  }

  /// Проверить, нужно ли показать напоминание
  bool shouldShowReminder() {
    final now = DateTime.now();
    final reminderTime = calculateReminderTime();

    if (reminderTime == null) return false;

    // Показываем напоминание, если текущее время больше времени напоминания
    // и меньше времени начала события
    return now.isAfter(reminderTime) && now.isBefore(startDate);
  }

  /// Проверить, активно ли событие сейчас
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Проверить, будущее ли событие
  bool get isFuture {
    final now = DateTime.now();
    return startDate.isAfter(now);
  }

  /// Проверить, прошедшее ли событие
  bool get isPast {
    final now = DateTime.now();
    return endDate.isBefore(now);
  }

  /// Получить иконку для типа события
  String get typeIcon {
    switch (type) {
      case CalendarEventType.tournament:
        return '🏆';
      case CalendarEventType.fishing:
        return '🎣';
    }
  }

  /// Получить цвет для типа события
  int get typeColor {
    switch (type) {
      case CalendarEventType.tournament:
        return 0xFF2196F3; // Синий для турниров
      case CalendarEventType.fishing:
        return 0xFF4CAF50; // Зеленый для рыбалки
    }
  }

  /// Получить отформатированное описание напоминания
  String getFormattedReminderDescription() {
    if (reminderType == ReminderType.none) {
      return 'Без напоминания';
    }

    if (reminderType == ReminderType.custom && customReminderDateTime != null) {
      final date = customReminderDateTime!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final reminderDate = DateTime(date.year, date.month, date.day);

      String dateStr;
      if (reminderDate == today) {
        dateStr = 'сегодня';
      } else if (reminderDate == tomorrow) {
        dateStr = 'завтра';
      } else {
        dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      }

      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      return '$dateStr в $timeStr';
    }

    return 'Настроить время';
  }
}

enum CalendarEventType {
  tournament,
  fishing,
}

// УПРОЩЕННЫЙ ENUM ТИПОВ НАПОМИНАНИЙ
enum ReminderType {
  none,    // Без напоминания
  custom,  // Настроить время
}

// РАСШИРЕНИЕ ДЛЯ ПОЛУЧЕНИЯ ЛОКАЛИЗОВАННЫХ НАЗВАНИЙ ТИПОВ НАПОМИНАНИЙ
extension ReminderTypeExtension on ReminderType {
  String get localizationKey {
    switch (this) {
      case ReminderType.none:
        return 'reminder_none';
      case ReminderType.custom:
        return 'reminder_custom';
    }
  }

  String get displayName {
    switch (this) {
      case ReminderType.none:
        return 'Без напоминания';
      case ReminderType.custom:
        return 'Настроить время';
    }
  }
}