// Путь: lib/services/calendar_event_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tournament_model.dart';
import '../screens/tournaments/tournament_detail_screen.dart';

class CalendarEventService {
  static final CalendarEventService _instance = CalendarEventService._internal();
  factory CalendarEventService() => _instance;
  CalendarEventService._internal();

  static const String _calendarEventsKey = 'calendar_events';

  /// Добавить турнир в календарь
  Future<void> addTournamentToCalendar({
    required TournamentModel tournament,
    required ReminderType reminderType,
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
        sourceId: tournament.id,
      );

      // Удаляем существующее событие, если есть
      events.removeWhere((e) => e.id == event.id);

      // Добавляем новое событие
      events.add(event);

      // Сохраняем
      await _saveCalendarEvents(events);

      debugPrint('Турнир ${tournament.name} добавлен в календарь');
    } catch (e) {
      debugPrint('Ошибка при добавлении турнира в календарь: $e');
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

  /// Удалить событие
  Future<void> removeEvent(String eventId) async {
    try {
      final events = await getCalendarEvents();
      events.removeWhere((e) => e.id == eventId);
      await _saveCalendarEvents(events);
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
  final String? sourceId; // ID источника (tournament ID, note ID, etc.)

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.location,
    this.description,
    required this.type,
    required this.reminderType,
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
      case 'ReminderType.oneHour':
        return ReminderType.oneHour;
      case 'ReminderType.oneDay':
        return ReminderType.oneDay;
      case 'ReminderType.oneWeek':
        return ReminderType.oneWeek;
      default:
        return ReminderType.none;
    }
  }

  /// Проверить, нужно ли показать напоминание
  bool shouldShowReminder() {
    final now = DateTime.now();

    switch (reminderType) {
      case ReminderType.none:
        return false;
      case ReminderType.oneHour:
        final reminderTime = startDate.subtract(const Duration(hours: 1));
        return now.isAfter(reminderTime) && now.isBefore(startDate);
      case ReminderType.oneDay:
        final reminderTime = startDate.subtract(const Duration(days: 1));
        return now.isAfter(reminderTime) && now.isBefore(startDate);
      case ReminderType.oneWeek:
        final reminderTime = startDate.subtract(const Duration(days: 7));
        return now.isAfter(reminderTime) && now.isBefore(startDate);
    }
  }
}

enum CalendarEventType {
  tournament,
  fishing,
}

enum ReminderType {
  none,
  oneHour,
  oneDay,
  oneWeek,
}