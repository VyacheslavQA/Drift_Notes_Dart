// Путь: lib/models/tournament_model.dart

class TournamentModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final int duration; // в часах
  final String sector;
  final String location;
  final String organizer;
  final String month; // для группировки
  final TournamentType type;

  TournamentModel({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.duration,
    required this.sector,
    required this.location,
    required this.organizer,
    required this.month,
    required this.type,
  });

  // Проверка, является ли турнир многодневным
  bool get isMultiDay => endDate != null && !isSameDay(startDate, endDate!);

  // Проверка, что две даты - один день
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Форматированная дата для отображения
  String get formattedDate {
    if (isMultiDay) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate!)}';
    }
    return _formatDate(startDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  // Проверка, прошел ли турнир
  bool get isPast => DateTime.now().isAfter(endDate ?? startDate);

  // Проверка, идет ли сейчас турнир
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate ?? startDate.add(Duration(hours: duration)));
  }

  // Проверка, будет ли турнир в будущем
  bool get isFuture => DateTime.now().isBefore(startDate);
}

enum TournamentType {
  championship, // Чемпионат
  cup, // Кубок
  tournament, // Турнир
  league, // Лига
  commercial, // Коммерческий
  casting, // Кастинг
}

extension TournamentTypeExtension on TournamentType {
  String get displayName {
    switch (this) {
      case TournamentType.championship:
        return 'Чемпионат';
      case TournamentType.cup:
        return 'Кубок';
      case TournamentType.tournament:
        return 'Турнир';
      case TournamentType.league:
        return 'Лига';
      case TournamentType.commercial:
        return 'Коммерческий';
      case TournamentType.casting:
        return 'Кастинг';
    }
  }

  String get icon {
    switch (this) {
      case TournamentType.championship:
        return '🏆';
      case TournamentType.cup:
        return '🥇';
      case TournamentType.tournament:
        return '🎯';
      case TournamentType.league:
        return '⚔️';
      case TournamentType.commercial:
        return '💰';
      case TournamentType.casting:
        return '🎣';
    }
  }
}