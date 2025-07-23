// Путь: lib/models/isar/fishing_note_entity.dart

import 'package:isar/isar.dart';

part 'fishing_note_entity.g.dart';

@Collection()
class FishingNoteEntity {
  Id id = Isar.autoIncrement; // Isar ID, auto-increment

  @Index(unique: true)
  String? firebaseId; // ID из Firestore

  late String title;

  String? description;

  late DateTime date;

  // 🔥 ДОБАВЛЕНО: Поддержка многодневных рыбалок
  DateTime? endDate; // Дата окончания (для многодневных рыбалок)
  bool isMultiDay = false; // Флаг многодневной рыбалки

  String? location;

  WeatherDataEntity? weatherData;

  List<BiteRecordEntity> biteRecords = [];

  bool isSynced = false; // Флаг синхронизации с Firebase

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

@embedded
class WeatherDataEntity {
  double? temperature; // Температура в градусах Цельсия
  double? feelsLike; // 🔥 ДОБАВЛЕНО: Ощущается как
  double? humidity; // Влажность в процентах
  double? windSpeed; // Скорость ветра в м/с
  String? windDirection; // Направление ветра
  double? pressure; // Давление в мм рт. ст.
  double? cloudCover; // 🔥 ДОБАВЛЕНО: Облачность в процентах
  bool isDay = true; // 🔥 ДОБАВЛЕНО: День/ночь
  String? sunrise; // 🔥 ДОБАВЛЕНО: Время восхода
  String? sunset; // 🔥 ДОБАВЛЕНО: Время заката
  String? condition; // Состояние погоды (ясно, облачно, дождь и т.д.)
  DateTime? recordedAt; // Время записи погодных данных
}

@embedded
class BiteRecordEntity {
  DateTime? time; // Время поклевки
  String? fishType; // Тип рыбы
  String? baitUsed; // Использованная приманка
  bool success = false; // Успешная ли была поклевка (поймали рыбу)
  double? fishWeight; // Вес рыбы в кг (если поймали)
  double? fishLength; // Длина рыбы в см (если поймали)
  String? notes; // Дополнительные заметки о поклевке
}