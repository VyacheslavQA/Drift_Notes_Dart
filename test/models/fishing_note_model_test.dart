// Путь: test/models/fishing_note_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:drift_notes_dart/models/fishing_note_model.dart';
import 'package:drift_notes_dart/services/calendar_event_service.dart';

void main() {
  group('FishingNoteModel Tests', () {
    late FishingNoteModel testNote;
    late BiteRecord testBiteRecord;
    late FishingWeather testWeather;

    setUp(() {
      testBiteRecord = BiteRecord(
        id: 'bite1',
        time: DateTime(2024, 1, 15, 10, 30),
        fishType: 'Щука',
        weight: 2.5,
        length: 50.0,
        notes: 'Хороший клев',
        dayIndex: 0,
        spotIndex: 0,
        photoUrls: ['photo1.jpg'],
      );

      testWeather = FishingWeather(
        temperature: 15.0,
        feelsLike: 12.0,
        humidity: 65,
        pressure: 1013.25,
        windSpeed: 5.0,
        windDirection: 'N',
        weatherDescription: 'Облачно',
        cloudCover: 75,
        moonPhase: 'Полнолуние',
        observationTime: DateTime(2024, 1, 15, 8, 0),
        sunrise: '07:30',
        sunset: '18:00',
        isDay: true,
      );

      testNote = FishingNoteModel(
        id: 'note1',
        userId: 'user1',
        location: 'Озеро Селигер',
        latitude: 57.1234,
        longitude: 33.4567,
        date: DateTime(2024, 1, 15, 6, 0),
        endDate: DateTime(2024, 1, 15, 18, 0),
        isMultiDay: false,
        tackle: 'Спиннинг',
        notes: 'Отличная рыбалка',
        photoUrls: ['photo1.jpg', 'photo2.jpg'],
        fishingType: 'Спиннинг',
        weather: testWeather,
        biteRecords: [testBiteRecord],
        dayBiteMaps: {'0': ['bite1']},
        fishingSpots: ['Основная точка', 'Второе место'],
        mapMarkers: [
          {'lat': 57.1234, 'lng': 33.4567, 'title': 'Точка 1'}
        ],
        coverPhotoUrl: 'cover.jpg',
        title: 'Рыбалка на Селигере',
        reminderEnabled: true,
        reminderType: ReminderType.custom,
        reminderTime: DateTime(2024, 1, 14, 20, 0),
      );
    });

    test('should create FishingNoteModel with all properties', () {
      expect(testNote.id, 'note1');
      expect(testNote.userId, 'user1');
      expect(testNote.location, 'Озеро Селигер');
      expect(testNote.latitude, 57.1234);
      expect(testNote.longitude, 33.4567);
      expect(testNote.tackle, 'Спиннинг');
      expect(testNote.notes, 'Отличная рыбалка');
      expect(testNote.photoUrls.length, 2);
      expect(testNote.biteRecords.length, 1);
      expect(testNote.reminderEnabled, true);
      expect(testNote.reminderType, ReminderType.custom);
    });

    test('should create BiteRecord with all properties', () {
      expect(testBiteRecord.id, 'bite1');
      expect(testBiteRecord.fishType, 'Щука');
      expect(testBiteRecord.weight, 2.5);
      expect(testBiteRecord.length, 50.0);
      expect(testBiteRecord.notes, 'Хороший клев');
      expect(testBiteRecord.photoUrls.length, 1);
    });

    test('should create FishingWeather with all properties', () {
      expect(testWeather.temperature, 15.0);
      expect(testWeather.humidity, 65);
      expect(testWeather.pressure, 1013.25);
      expect(testWeather.windSpeed, 5.0);
      expect(testWeather.weatherDescription, 'Облачно');
    });

    test('should convert FishingNoteModel to JSON and back', () {
      final json = testNote.toJson();
      final recreatedNote = FishingNoteModel.fromJson(json, id: testNote.id);

      expect(recreatedNote.id, testNote.id);
      expect(recreatedNote.location, testNote.location);
      expect(recreatedNote.latitude, testNote.latitude);
      expect(recreatedNote.longitude, testNote.longitude);
      expect(recreatedNote.tackle, testNote.tackle);
      expect(recreatedNote.biteRecords.length, testNote.biteRecords.length);
      expect(recreatedNote.reminderEnabled, testNote.reminderEnabled);
    });

    test('should convert BiteRecord to JSON and back', () {
      final json = testBiteRecord.toJson();
      final recreatedRecord = BiteRecord.fromJson(json);

      expect(recreatedRecord.id, testBiteRecord.id);
      expect(recreatedRecord.fishType, testBiteRecord.fishType);
      expect(recreatedRecord.weight, testBiteRecord.weight);
      expect(recreatedRecord.length, testBiteRecord.length);
      expect(recreatedRecord.notes, testBiteRecord.notes);
    });

    test('should convert FishingWeather to JSON and back', () {
      final json = testWeather.toJson();
      final recreatedWeather = FishingWeather.fromJson(json);

      expect(recreatedWeather.temperature, testWeather.temperature);
      expect(recreatedWeather.humidity, testWeather.humidity);
      expect(recreatedWeather.pressure, testWeather.pressure);
      expect(recreatedWeather.windSpeed, testWeather.windSpeed);
    });

    test('should handle complex FishingNoteModel with multiple bite records', () {
      final biteRecords = [
        BiteRecord(
          id: 'bite1',
          time: DateTime(2024, 1, 15, 10, 30),
          fishType: 'Щука',
          weight: 2.5,
          length: 50.0,
        ),
        BiteRecord(
          id: 'bite2',
          time: DateTime(2024, 1, 15, 14, 15),
          fishType: 'Окунь',
          weight: 0.8,
          length: 25.0,
        ),
        BiteRecord(
          id: 'bite3',
          time: DateTime(2024, 1, 15, 16, 45),
          fishType: 'Плотва',
          weight: 0.3,
          length: 15.0,
        ),
      ];

      final complexNote = testNote.copyWith(
        biteRecords: biteRecords,
      );

      expect(complexNote.biteRecords.length, 3);
      expect(complexNote.biggestFish?.weight, 2.5);
      expect(complexNote.totalFishWeight, closeTo(3.6, 0.01));
    });

    test('should handle copyWith for FishingNoteModel', () {
      final updatedNote = testNote.copyWith(
        location: 'Волга',
        tackle: 'Фидер',
        notes: 'Обновленные заметки',
        reminderEnabled: false,
      );

      expect(updatedNote.location, 'Волга');
      expect(updatedNote.tackle, 'Фидер');
      expect(updatedNote.notes, 'Обновленные заметки');
      expect(updatedNote.reminderEnabled, false);
      // Проверяем, что остальные поля не изменились
      expect(updatedNote.id, testNote.id);
      expect(updatedNote.userId, testNote.userId);
    });

    test('should handle copyWith for BiteRecord', () {
      final updatedRecord = testBiteRecord.copyWith(
        fishType: 'Судак',
        weight: 3.0,
        length: 60.0,
      );

      expect(updatedRecord.fishType, 'Судак');
      expect(updatedRecord.weight, 3.0);
      expect(updatedRecord.length, 60.0);
      // Проверяем, что остальные поля не изменились
      expect(updatedRecord.id, testBiteRecord.id);
      expect(updatedRecord.time, testBiteRecord.time);
    });

    test('should calculate total fish weight correctly', () {
      final biteRecords = [
        BiteRecord(id: '1', time: DateTime.now(), weight: 1.5),
        BiteRecord(id: '2', time: DateTime.now(), weight: 2.0),
        BiteRecord(id: '3', time: DateTime.now(), weight: 0.0), // Без веса
        BiteRecord(id: '4', time: DateTime.now(), weight: 1.2),
      ];

      final noteWithMultipleFish = testNote.copyWith(biteRecords: biteRecords);
      expect(noteWithMultipleFish.totalFishWeight, 4.7);
    });

    test('should find biggest fish correctly', () {
      final biteRecords = [
        BiteRecord(id: '1', time: DateTime.now(), weight: 1.5),
        BiteRecord(id: '2', time: DateTime.now(), weight: 3.2), // Самая большая
        BiteRecord(id: '3', time: DateTime.now(), weight: 0.8),
      ];

      final noteWithMultipleFish = testNote.copyWith(biteRecords: biteRecords);
      expect(noteWithMultipleFish.biggestFish?.weight, 3.2);
    });

    test('should handle empty bite records', () {
      final noteWithoutFish = testNote.copyWith(biteRecords: []);

      expect(noteWithoutFish.totalFishWeight, 0.0);
      expect(noteWithoutFish.biggestFish, null);
    });

    test('should check if fishing is planned', () {
      final futureDate = DateTime.now().add(Duration(days: 1));
      final pastDate = DateTime.now().subtract(Duration(days: 1));

      final plannedNote = testNote.copyWith(date: futureDate);
      final pastNote = testNote.copyWith(date: pastDate);

      expect(plannedNote.isPlanned, true);
      expect(pastNote.isPlanned, false);
    });

    test('should calculate reminder time correctly', () {
      final noteWithReminder = testNote.copyWith(
        reminderEnabled: true,
        reminderType: ReminderType.custom,
        reminderTime: DateTime(2024, 1, 14, 20, 0),
      );

      final reminderTime = noteWithReminder.calculateReminderTime();
      expect(reminderTime, DateTime(2024, 1, 14, 20, 0));
    });

    test('should handle reminder disabled', () {
      final noteWithoutReminder = testNote.copyWith(
        reminderEnabled: false,
      );

      final reminderTime = noteWithoutReminder.calculateReminderTime();
      expect(reminderTime, null);
    });

    test('should parse reminder type from string correctly', () {
      final jsonWithCustomReminder = {
        'id': 'test',
        'userId': 'user1',
        'location': 'Test',
        'date': DateTime.now().millisecondsSinceEpoch,
        'reminderType': 'ReminderType.custom',
        'reminderEnabled': true,
      };

      final note = FishingNoteModel.fromJson(jsonWithCustomReminder);
      expect(note.reminderType, ReminderType.custom);
    });
  });
}