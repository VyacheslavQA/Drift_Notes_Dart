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

  // 🔥 ПОДДЕРЖКА многодневных рыбалок
  DateTime? endDate; // Дата окончания (для многодневных рыбалок)
  bool isMultiDay = false; // Флаг многодневной рыбалки

  String? location;

  // ✅ ДОБАВЛЕНО: Основные недостающие поля
  String? tackle;           // Снасти
  String? fishingType;      // Вид рыбалки (carp_fishing, etc.)
  String? notes;            // Заметки (отдельно от description)
  double? latitude;         // Широта
  double? longitude;        // Долгота
  List<String> photoUrls = []; // Фото заметки

  // ✅ ДОБАВЛЕНО: JSON строка для mapMarkers (сложная структура)
  String? mapMarkersJson;   // JSON строка с маркерами карты

  // ✅ ДОБАВЛЕНО: AI предсказание
  AiPredictionEntity? aiPrediction;

  WeatherDataEntity? weatherData;

  List<BiteRecordEntity> biteRecords = [];

  bool isSynced = false; // Флаг синхронизации с Firebase

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

// ✅ ДОПОЛНЕНО: WeatherDataEntity с недостающими полями
@embedded
class WeatherDataEntity {
  double? temperature; // Температура в градусах Цельсия
  double? feelsLike; // Ощущается как
  double? humidity; // Влажность в процентах
  double? windSpeed; // Скорость ветра в м/с
  String? windDirection; // Направление ветра
  double? pressure; // Давление в мм рт. ст.
  double? cloudCover; // Облачность в процентах
  bool isDay = true; // День/ночь
  String? sunrise; // Время восхода
  String? sunset; // Время заката
  String? condition; // Состояние погоды (ясно, облачно, дождь и т.д.)
  DateTime? recordedAt; // Время записи погодных данных

  // ✅ ДОБАВЛЕНО: Дополнительная временная метка из Firebase
  int? timestamp; // Timestamp из Firebase weather объекта
}

// ✅ ДОПОЛНЕНО: BiteRecordEntity с недостающими полями
@embedded
class BiteRecordEntity {
  String? biteId; // ✅ ДОБАВЛЕНО: ID поклевки из Firebase
  DateTime? time; // Время поклевки
  String? fishType; // Тип рыбы
  String? baitUsed; // Использованная приманка
  bool success = false; // Успешная ли была поклевка (поймали рыбу)
  double? fishWeight; // Вес рыбы в кг (если поймали)
  double? fishLength; // Длина рыбы в см (если поймали)
  String? notes; // Дополнительные заметки о поклевке

  // ✅ ДОБАВЛЕНО: Фото поклевки
  List<String> photoUrls = []; // Фото конкретной поклевки
}

// ✅ НОВОЕ: AI предсказание
@embedded
class AiPredictionEntity {
  String? activityLevel; // Уровень активности (ActivityLevel.excellent)
  int? confidencePercent; // Процент уверенности (80)
  String? fishingType; // Тип рыбалки для AI (может отличаться от основного)
  int? overallScore; // Общий балл (100)
  String? recommendation; // Рекомендация текстом
  int? timestamp; // Временная метка предсказания

  // ✅ ДОБАВЛЕНО: Советы как JSON строка (массив строк)
  String? tipsJson; // JSON строка с массивом советов ["совет1", "совет2"]
}