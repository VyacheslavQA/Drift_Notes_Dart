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
    return now.isAfter(startDate) &&
        now.isBefore(endDate ?? startDate.add(Duration(hours: duration)));
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
  carpFishing, // Карповая рыбалка
  casting, // Кастинг
  spinning, // Спиннинг
  feeder, // Фидер
  floatFishing, // Поплавочная
  iceFishing, // Зимняя рыбалка
  flyFishing, // Нахлыст
  other, // Другое
}

extension FishingTypeExtension on FishingType {
  // Получение правильного ключа локализации
  String get localizationKey {
    switch (this) {
      case FishingType.carpFishing:
        return 'carp_fishing_type';
      case FishingType.casting:
        return 'casting_type';
      case FishingType.spinning:
        return 'spinning_type';
      case FishingType.feeder:
        return 'feeder_type';
      case FishingType.floatFishing:
        return 'float_fishing_type';
      case FishingType.iceFishing:
        return 'ice_fishing_type';
      case FishingType.flyFishing:
        return 'fly_fishing_type';
      case FishingType.other:
        return 'other_fishing_type';
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

  // Путь к PNG иконке вместо эмодзи
  String get iconPath {
    switch (this) {
      case FishingType.carpFishing:
        return 'assets/images/fishing_types/carp_fishing.png';
      case FishingType.casting:
        return 'assets/images/fishing_types/other.png'; // Нет специальной иконки для кастинга, используем "other"
      case FishingType.spinning:
        return 'assets/images/fishing_types/spinning.png';
      case FishingType.feeder:
        return 'assets/images/fishing_types/feeder.png';
      case FishingType.floatFishing:
        return 'assets/images/fishing_types/float_fishing.png';
      case FishingType.iceFishing:
        return 'assets/images/fishing_types/ice_fishing.png';
      case FishingType.flyFishing:
        return 'assets/images/fishing_types/fly_fishing.png';
      case FishingType.other:
        return 'assets/images/fishing_types/other.png';
    }
  }

  // Эмодзи как fallback (оставляем для совместимости)
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
  championship, // Чемпионат
  cup, // Кубок
  league, // Лига
  tournament, // Турнир
}

extension TournamentCategoryExtension on TournamentCategory {
  // Получение правильного ключа локализации
  String get localizationKey {
    switch (this) {
      case TournamentCategory.championship:
        return 'championship';
      case TournamentCategory.cup:
        return 'cup';
      case TournamentCategory.league:
        return 'league';
      case TournamentCategory.tournament:
        return 'tournament';
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
