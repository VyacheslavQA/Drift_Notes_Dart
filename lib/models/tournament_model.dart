// Путь: lib/models/tournament_model.dart

class TournamentModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final int duration; // в часах
  final String location;
  final String organizer;
  final String month; // для группировки
  final FishingType fishingType; // новое поле - тип рыбалки

  TournamentModel({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.duration,
    required this.location,
    required this.organizer,
    required this.month,
    required this.fishingType,
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

  // Определение типа турнира по названию
  TournamentCategory get category {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('чемпионат')) {
      return TournamentCategory.championship;
    } else if (lowerName.contains('кубок')) {
      return TournamentCategory.cup;
    } else if (lowerName.contains('лига')) {
      return TournamentCategory.league;
    } else {
      return TournamentCategory.tournament;
    }
  }
}

// Типы рыбалки
enum FishingType {
  carpFishing,    // Карповая рыбалка
  casting,        // Кастинг
  spinning,       // Спиннинг
  feeder,         // Фидер
  floatFishing,   // Поплавочная
  iceFishing,     // Зимняя рыбалка
  flyFishing,     // Нахлыст
  other,          // Другое
}

extension FishingTypeExtension on FishingType {
  String getDisplayName(Function(String) translate) {
    switch (this) {
      case FishingType.carpFishing:
        return translate('carp_fishing_type');
      case FishingType.casting:
        return translate('casting_type');
      case FishingType.spinning:
        return translate('spinning_type');
      case FishingType.feeder:
        return translate('feeder_type');
      case FishingType.floatFishing:
        return translate('float_fishing_type');
      case FishingType.iceFishing:
        return translate('ice_fishing_type');
      case FishingType.flyFishing:
        return translate('fly_fishing_type');
      case FishingType.other:
        return translate('other_fishing_type');
    }
  }

  // Fallback для обратной совместимости
  String get displayName {
    switch (this) {
      case FishingType.carpFishing:
        return 'Карповая рыбалка';
      case FishingType.casting:
        return 'Кастинг';
      case FishingType.spinning:
        return 'Спиннинг';
      case FishingType.feeder:
        return 'Фидер';
      case FishingType.floatFishing:
        return 'Поплавочная';
      case FishingType.iceFishing:
        return 'Зимняя рыбалка';
      case FishingType.flyFishing:
        return 'Нахлыст';
      case FishingType.other:
        return 'Другое';
    }
  }

  String get icon {
    switch (this) {
      case FishingType.carpFishing:
        return '🐟';
      case FishingType.casting:
        return '🎯';
      case FishingType.spinning:
        return '🎣';
      case FishingType.feeder:
        return '🪝';
      case FishingType.floatFishing:
        return '🎈';
      case FishingType.iceFishing:
        return '❄️';
      case FishingType.flyFishing:
        return '🪶';
      case FishingType.other:
        return '🏆';
    }
  }
}

// Категории турниров (для отображения типа)
enum TournamentCategory {
  championship,   // Чемпионат
  cup,           // Кубок
  league,        // Лига
  tournament,    // Турнир
}

extension TournamentCategoryExtension on TournamentCategory {
  String getDisplayName(Function(String) translate) {
    switch (this) {
      case TournamentCategory.championship:
        return translate('championship');
      case TournamentCategory.cup:
        return translate('cup');
      case TournamentCategory.league:
        return translate('league');
      case TournamentCategory.tournament:
        return translate('tournament');
    }
  }

  // Fallback для обратной совместимости
  String get displayName {
    switch (this) {
      case TournamentCategory.championship:
        return 'Чемпионат';
      case TournamentCategory.cup:
        return 'Кубок';
      case TournamentCategory.league:
        return 'Лига';
      case TournamentCategory.tournament:
        return 'Турнир';
    }
  }

  String get icon {
    switch (this) {
      case TournamentCategory.championship:
        return '🏆';
      case TournamentCategory.cup:
        return '🥇';
      case TournamentCategory.league:
        return '⚔️';
      case TournamentCategory.tournament:
        return '🎯';
    }
  }
}