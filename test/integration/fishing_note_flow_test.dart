// Путь: test/integration/fishing_note_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:drift_notes_dart/models/fishing_note_model.dart';
import 'package:drift_notes_dart/services/calendar_event_service.dart';

void main() {
  group('Fishing Note Integration Tests', () {
    late FishingNoteModel testNote;

    setUp(() {
      testNote = FishingNoteModel(
        id: 'integration_test_note',
        userId: 'test_user',
        location: 'Тестовое озеро',
        latitude: 55.7558,
        longitude: 37.6173,
        date: DateTime(2024, 6, 15, 6, 0),
        endDate: DateTime(2024, 6, 15, 18, 0),
        tackle: 'Спиннинг',
        notes: 'Интеграционный тест рыбалки',
        fishingType: 'Спиннинг',
        reminderEnabled: true,
        reminderType: ReminderType.custom,
        reminderTime: DateTime(2024, 6, 14, 20, 0),
      );
    });

    test('should create complete fishing note with all data', () {
      // Создаем полную заметку о рыбалке
      final weather = FishingWeather(
        temperature: 20.0,
        humidity: 60,
        pressure: 1015.0,
        windSpeed: 3.0,
        windDirection: 'SW',
        weatherDescription: 'Ясно',
        observationTime: DateTime(2024, 6, 15, 6, 0),
        isDay: true,
      );

      final biteRecords = [
        BiteRecord(
          id: 'bite_1',
          time: DateTime(2024, 6, 15, 8, 30),
          fishType: 'Щука',
          weight: 2.1,
          length: 45.0,
          notes: 'Поймал на воблер',
          dayIndex: 0,
          spotIndex: 0,
        ),
        BiteRecord(
          id: 'bite_2',
          time: DateTime(2024, 6, 15, 12, 15),
          fishType: 'Окунь',
          weight: 0.8,
          length: 25.0,
          notes: 'На блесну',
          dayIndex: 0,
          spotIndex: 1,
        ),
      ];

      final completeNote = testNote.copyWith(
        weather: weather,
        biteRecords: biteRecords,
        photoUrls: ['photo1.jpg', 'photo2.jpg'],
        fishingSpots: ['Основная точка', 'У камышей', 'Глубокое место'],
        coverPhotoUrl: 'cover_photo.jpg',
        title: 'Отличная рыбалка на озере',
      );

      // Проверяем, что все данные корректно установлены
      expect(completeNote.weather?.temperature, 20.0);
      expect(completeNote.biteRecords.length, 2);
      expect(completeNote.photoUrls.length, 2);
      expect(completeNote.fishingSpots.length, 3);
      expect(completeNote.totalFishWeight, closeTo(2.9, 0.01));
      expect(completeNote.biggestFish?.weight, 2.1);
    });

    test('should handle full fishing note lifecycle', () {
      // 1. Создание новой заметки
      var note = FishingNoteModel(
        id: 'lifecycle_test',
        userId: 'test_user',
        location: 'Река Волга',
        date: DateTime.now().add(Duration(days: 1)), // Планируемая рыбалка
        tackle: 'Фидер',
        notes: 'Планируем рыбалку на фидер',
      );

      // Проверяем, что это планируемая рыбалка
      expect(note.isPlanned, true);
      expect(note.biteRecords.isEmpty, true);

      // 2. Добавление первой рыбы
      final firstBite = BiteRecord(
        id: 'bite_1',
        time: DateTime.now(),
        fishType: 'Лещ',
        weight: 1.2,
        length: 35.0,
        notes: 'Первая рыба дня',
      );

      note = note.copyWith(
        biteRecords: [firstBite],
      );

      expect(note.biteRecords.length, 1);
      expect(note.totalFishWeight, 1.2);
      expect(note.biggestFish?.weight, 1.2);

      // 3. Добавление еще рыбы
      final secondBite = BiteRecord(
        id: 'bite_2',
        time: DateTime.now(),
        fishType: 'Плотва',
        weight: 0.4,
        length: 20.0,
        notes: 'Вторая рыба',
      );

      note = note.copyWith(
        biteRecords: [...note.biteRecords, secondBite],
      );

      expect(note.biteRecords.length, 2);
      expect(note.totalFishWeight, 1.6);
      expect(note.biggestFish?.weight, 1.2); // Лещ все еще самый большой

      // 4. Добавление более крупной рыбы
      final bigFish = BiteRecord(
        id: 'bite_3',
        time: DateTime.now(),
        fishType: 'Судак',
        weight: 2.8,
        length: 55.0,
        notes: 'Трофейная рыба!',
      );

      note = note.copyWith(
        biteRecords: [...note.biteRecords, bigFish],
      );

      expect(note.biteRecords.length, 3);
      expect(note.totalFishWeight, 4.4);
      expect(note.biggestFish?.weight, 2.8); // Теперь судак самый большой

      // 5. Обновление заметок и фото
      note = note.copyWith(
        notes: 'Отличный день! Поймал трофейного судака',
        photoUrls: ['fish1.jpg', 'fish2.jpg', 'trophy.jpg'],
        coverPhotoUrl: 'trophy.jpg',
        title: 'Трофейная рыбалка на Волге',
      );

      expect(note.photoUrls.length, 3);
      expect(note.title, 'Трофейная рыбалка на Волге');
    });

    test('should serialize and deserialize complex fishing note', () {
      // Создаем сложную заметку с множеством данных
      final complexNote = testNote.copyWith(
        weather: FishingWeather(
          temperature: 18.0,
          humidity: 70,
          pressure: 1010.0,
          windSpeed: 5.0,
          windDirection: 'N',
          weatherDescription: 'Переменная облачность',
          cloudCover: 50,
          moonPhase: 'Растущая луна',
          observationTime: DateTime(2024, 6, 15, 6, 0),
          sunrise: '05:30',
          sunset: '21:00',
          isDay: true,
        ),
        biteRecords: [
          BiteRecord(
            id: 'complex_bite_1',
            time: DateTime(2024, 6, 15, 9, 0),
            fishType: 'Карп',
            weight: 3.5,
            length: 60.0,
            notes: 'Сопротивлялся 15 минут',
            photoUrls: ['carp_photo.jpg'],
          ),
          BiteRecord(
            id: 'complex_bite_2',
            time: DateTime(2024, 6, 15, 15, 30),
            fishType: 'Щука',
            weight: 4.2,
            length: 70.0,
            notes: 'Поймал на живца',
            photoUrls: ['pike_photo1.jpg', 'pike_photo2.jpg'],
          ),
        ],
        photoUrls: ['sunrise.jpg', 'setup.jpg', 'catch1.jpg', 'catch2.jpg'],
        mapMarkers: [
          {
            'lat': 55.7558,
            'lng': 37.6173,
            'title': 'Точка 1',
            'description': 'Основное место'
          },
          {
            'lat': 55.7568,
            'lng': 37.6183,
            'title': 'Точка 2',
            'description': 'Запасное место'
          },
        ],
        dayBiteMaps: {
          '0': ['complex_bite_1', 'complex_bite_2']
        },
        fishingSpots: ['Основная точка', 'У коряги', 'Тихая заводь'],
        aiPrediction: {
          'success_probability': 0.85,
          'best_time': '08:00-10:00',
          'recommended_bait': 'Червь'
        },
      );

      // Сериализуем в JSON
      final json = complexNote.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['location'], 'Тестовое озеро');
      expect(json['biteRecords'], isA<List>());
      expect(json['weather'], isA<Map<String, dynamic>>());

      // Десериализуем обратно
      final deserializedNote = FishingNoteModel.fromJson(json, id: complexNote.id);

      // Проверяем корректность десериализации
      expect(deserializedNote.id, complexNote.id);
      expect(deserializedNote.location, complexNote.location);
      expect(deserializedNote.biteRecords.length, complexNote.biteRecords.length);
      expect(deserializedNote.weather?.temperature, complexNote.weather?.temperature);
      expect(deserializedNote.photoUrls.length, complexNote.photoUrls.length);
      expect(deserializedNote.fishingSpots.length, complexNote.fishingSpots.length);
      expect(deserializedNote.totalFishWeight, complexNote.totalFishWeight);
      expect(deserializedNote.biggestFish?.weight, complexNote.biggestFish?.weight);
    });

    test('should handle reminder system workflow', () {
      final plannedDate = DateTime.now().add(Duration(days: 2));
      final reminderTime = plannedDate.subtract(Duration(hours: 2));

      var noteWithReminder = testNote.copyWith(
        date: plannedDate,
        reminderEnabled: true,
        reminderType: ReminderType.custom,
        reminderTime: reminderTime,
      );

      // Проверяем настройки напоминания
      expect(noteWithReminder.reminderEnabled, true);
      expect(noteWithReminder.reminderType, ReminderType.custom);
      expect(noteWithReminder.calculateReminderTime(), reminderTime);

      // Отключаем напоминание
      noteWithReminder = noteWithReminder.copyWith(
        reminderEnabled: false,
      );

      expect(noteWithReminder.calculateReminderTime(), null);
      expect(noteWithReminder.shouldShowReminder(), false);
    });

    test('should handle multi-day fishing trip', () {
      final startDate = DateTime(2024, 7, 1, 6, 0);
      final endDate = DateTime(2024, 7, 3, 18, 0);

      final multiDayTrip = testNote.copyWith(
        date: startDate,
        endDate: endDate,
        isMultiDay: true,
        title: 'Трехдневная рыбалка',
        dayBiteMaps: {
          '0': ['day1_bite1', 'day1_bite2'],
          '1': ['day2_bite1'],
          '2': ['day3_bite1', 'day3_bite2', 'day3_bite3'],
        },
        biteRecords: [
          // День 1
          BiteRecord(id: 'day1_bite1', time: startDate.add(Duration(hours: 2)), fishType: 'Окунь', weight: 0.5, dayIndex: 0),
          BiteRecord(id: 'day1_bite2', time: startDate.add(Duration(hours: 6)), fishType: 'Щука', weight: 1.8, dayIndex: 0),
          // День 2
          BiteRecord(id: 'day2_bite1', time: startDate.add(Duration(days: 1, hours: 4)), fishType: 'Судак', weight: 2.2, dayIndex: 1),
          // День 3
          BiteRecord(id: 'day3_bite1', time: startDate.add(Duration(days: 2, hours: 1)), fishType: 'Лещ', weight: 1.0, dayIndex: 2),
          BiteRecord(id: 'day3_bite2', time: startDate.add(Duration(days: 2, hours: 3)), fishType: 'Плотва', weight: 0.3, dayIndex: 2),
          BiteRecord(id: 'day3_bite3', time: startDate.add(Duration(days: 2, hours: 8)), fishType: 'Карась', weight: 0.7, dayIndex: 2),
        ],
      );

      expect(multiDayTrip.isMultiDay, true);
      expect(multiDayTrip.biteRecords.length, 6);
      expect(multiDayTrip.dayBiteMaps.keys.length, 3);
      expect(multiDayTrip.totalFishWeight, 6.5);
      expect(multiDayTrip.biggestFish?.weight, 2.2);

      // Проверяем распределение по дням
      expect(multiDayTrip.dayBiteMaps['0']?.length, 2); // День 1: 2 рыбы
      expect(multiDayTrip.dayBiteMaps['1']?.length, 1); // День 2: 1 рыба
      expect(multiDayTrip.dayBiteMaps['2']?.length, 3); // День 3: 3 рыбы
    });

    test('should validate data consistency after operations', () {
      var note = testNote;

      // Добавляем несколько записей о рыбе
      final bites = [
        BiteRecord(id: '1', time: DateTime.now(), fishType: 'Рыба 1', weight: 1.0),
        BiteRecord(id: '2', time: DateTime.now(), fishType: 'Рыба 2', weight: 2.0),
        BiteRecord(id: '3', time: DateTime.now(), fishType: 'Рыба 3', weight: 1.5),
      ];

      note = note.copyWith(biteRecords: bites);

      // Проверяем консистентность данных
      expect(note.biteRecords.length, 3);
      expect(note.totalFishWeight, 4.5);
      expect(note.biggestFish?.id, '2'); // Рыба с весом 2.0

      // Обновляем одну запись
      final updatedBites = note.biteRecords.map((bite) {
        if (bite.id == '3') {
          return bite.copyWith(weight: 3.0); // Делаем третью рыбу самой большой
        }
        return bite;
      }).toList();

      note = note.copyWith(biteRecords: updatedBites);

      // Проверяем обновленные данные
      expect(note.totalFishWeight, 6.0);
      expect(note.biggestFish?.id, '3'); // Теперь третья рыба самая большая

      // Сериализация и десериализация должны сохранить консистентность
      final json = note.toJson();
      final deserializedNote = FishingNoteModel.fromJson(json, id: note.id);

      expect(deserializedNote.totalFishWeight, note.totalFishWeight);
      expect(deserializedNote.biggestFish?.id, note.biggestFish?.id);
      expect(deserializedNote.biteRecords.length, note.biteRecords.length);
    });
  });
}