// Путь: lib/services/data_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'isar_service.dart';
import '../repositories/user_repository.dart';

class DataExportService {
  final IsarService _isarService = IsarService.instance;
  final UserRepository _userRepository = UserRepository();

  /// Основной метод экспорта всех данных пользователя
  Future<bool> exportAllUserData([Map<String, String>? localizations]) async {
    try {
      debugPrint('🔄 Начинаем экспорт данных пользователя...');

      // Получаем ID пользователя
      final userId = _userRepository.currentUserId;
      if (userId == null) {
        debugPrint('❌ Пользователь не авторизован');
        return false;
      }

      debugPrint('👤 Экспортируем данные пользователя: $userId');

      // Собираем все данные
      final exportData = await _collectAllUserData(userId);

      // Создаем ZIP архив
      final zipFile = await _createZipArchive(exportData, userId, localizations);

      if (zipFile != null) {
        // Сохраняем в Downloads или делимся файлом
        await _saveOrShareFile(zipFile);
        debugPrint('✅ Экспорт данных завершен успешно');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Ошибка при экспорте данных: $e');
      return false;
    }
  }

  /// Сбор всех данных пользователя
  Future<Map<String, dynamic>> _collectAllUserData(String userId) async {
    debugPrint('📊 Собираем данные пользователя...');

    final exportData = <String, dynamic>{
      'export_info': {
        'user_id': userId,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.2+18',
        'export_version': '1.0.0',
      },
    };

    try {
      // 1. Профиль пользователя
      debugPrint('👤 Экспортируем профиль пользователя...');
      final userProfile = await _userRepository.getCurrentUserData();
      if (userProfile != null) {
        exportData['user_profile'] = userProfile.toJson();
      }

      // 2. Заметки рыбалки
      debugPrint('🎣 Экспортируем заметки рыбалки...');
      final fishingNotes = await _isarService.getAllFishingNotes();
      exportData['fishing_notes'] = {
        'count': fishingNotes.length,
        'data': fishingNotes.map((note) => {
          'id': note.id,
          'firebase_id': note.firebaseId,
          'user_id': note.userId,
          'title': note.title,
          'description': note.description,
          'date': note.date.toIso8601String(),
          'end_date': note.endDate?.toIso8601String(),
          'is_multi_day': note.isMultiDay,
          'location': note.location,
          'latitude': note.latitude,
          'longitude': note.longitude,
          'fishing_type': note.fishingType,
          'tackle': note.tackle,
          'notes': note.notes,
          'photo_urls': note.photoUrls,
          'map_markers_json': note.mapMarkersJson,
          'weather_data': note.weatherData != null ? {
            'temperature': note.weatherData!.temperature,
            'feels_like': note.weatherData!.feelsLike,
            'humidity': note.weatherData!.humidity,
            'wind_speed': note.weatherData!.windSpeed,
            'wind_direction': note.weatherData!.windDirection,
            'pressure': note.weatherData!.pressure,
            'cloud_cover': note.weatherData!.cloudCover,
            'is_day': note.weatherData!.isDay,
            'sunrise': note.weatherData!.sunrise,
            'sunset': note.weatherData!.sunset,
            'condition': note.weatherData!.condition,
            'recorded_at': note.weatherData!.recordedAt?.toIso8601String(),
            'timestamp': note.weatherData!.timestamp,
          } : null,
          'bite_records': note.biteRecords.map((bite) => {
            'bite_id': bite.biteId,
            'time': bite.time?.toIso8601String(),
            'fish_type': bite.fishType,
            'bait_used': bite.baitUsed,
            'success': bite.success,
            'fish_weight': bite.fishWeight,
            'fish_length': bite.fishLength,
            'notes': bite.notes,
            'photo_urls': bite.photoUrls,
            'day_index': bite.dayIndex,
            'spot_index': bite.spotIndex,
          }).toList(),
          'ai_prediction': note.aiPrediction != null ? {
            'activity_level': note.aiPrediction!.activityLevel,
            'confidence_percent': note.aiPrediction!.confidencePercent,
            'fishing_type': note.aiPrediction!.fishingType,
            'overall_score': note.aiPrediction!.overallScore,
            'recommendation': note.aiPrediction!.recommendation,
            'timestamp': note.aiPrediction!.timestamp,
            'tips_json': note.aiPrediction!.tipsJson,
          } : null,
          'created_at': note.createdAt.toIso8601String(),
          'updated_at': note.updatedAt.toIso8601String(),
          'is_synced': note.isSynced,
          'marked_for_deletion': note.markedForDeletion,
        }).toList(),
      };

      // 3. Маркерные карты
      debugPrint('🗺️ Экспортируем маркерные карты...');
      final markerMaps = await _isarService.getAllMarkerMaps(userId);
      exportData['marker_maps'] = {
        'count': markerMaps.length,
        'data': markerMaps.map((map) => {
          'id': map.id,
          'firebase_id': map.firebaseId,
          'user_id': map.userId,
          'name': map.name,
          'date': map.date.toIso8601String(),
          'sector': map.sector,
          'note_ids': map.noteIds,
          'note_names': map.noteNames,
          'markers': map.markers, // Уже декодированный JSON
          'markers_count': map.markersCount,
          'attached_notes_text': map.attachedNotesText,
          'created_at': map.createdAt.toIso8601String(),
          'updated_at': map.updatedAt.toIso8601String(),
          'is_synced': map.isSynced,
          'marked_for_deletion': map.markedForDeletion,
        }).toList(),
      };

      // 4. Заметки бюджета
      debugPrint('💰 Экспортируем заметки бюджета...');
      final budgetNotes = await _isarService.getAllBudgetNotes(userId);
      exportData['budget_notes'] = {
        'count': budgetNotes.length,
        'data': budgetNotes.map((note) => {
          'id': note.id,
          'firebase_id': note.firebaseId,
          'user_id': note.userId,
          'date': note.date.toIso8601String(),
          'end_date': note.endDate?.toIso8601String(),
          'is_multi_day': note.isMultiDay,
          'location_name': note.locationName,
          'notes': note.notes,
          'currency': note.currency,
          'total_amount': note.totalAmount,
          'expense_count': note.expenseCount,
          'expenses': note.expenses.map((expense) => {
            'id': expense.id,
            'user_id': expense.userId,
            'trip_id': expense.tripId,
            'amount': expense.amount,
            'category': expense.category.id,
            'category_icon': expense.category.icon,
            'description': expense.description,
            'date': expense.date.toIso8601String(),
            'currency': expense.currency,
            'notes': expense.notes,
            'location': expense.location != null ? {
              'latitude': expense.location!.latitude,
              'longitude': expense.location!.longitude,
            } : null,
            'location_name': expense.locationName,
            'fishing_note_id': expense.fishingNoteId,
            'is_synced': expense.isSynced,
            'created_at': expense.createdAt.toIso8601String(),
            'updated_at': expense.updatedAt.toIso8601String(),
          }).toList(),
          'created_at': note.createdAt.toIso8601String(),
          'updated_at': note.updatedAt.toIso8601String(),
          'last_sync_at': note.lastSyncAt?.toIso8601String(),
          'is_synced': note.isSynced,
          'marked_for_deletion': note.markedForDeletion,
        }).toList(),
      };

      // 5. Согласия пользователя
      debugPrint('📄 Экспортируем согласия пользователя...');
      try {
        final policyAcceptance = await _isarService.getPolicyAcceptanceByUserId(userId);
        if (policyAcceptance != null) {
          exportData['user_consents'] = {
            'privacy_policy_accepted': policyAcceptance.privacyPolicyAccepted,
            'privacy_policy_version': policyAcceptance.privacyPolicyVersion,
            'privacy_policy_hash': policyAcceptance.privacyPolicyHash,
            'terms_of_service_accepted': policyAcceptance.termsOfServiceAccepted,
            'terms_of_service_version': policyAcceptance.termsOfServiceVersion,
            'terms_of_service_hash': policyAcceptance.termsOfServiceHash,
            'consent_language': policyAcceptance.consentLanguage,
            'consent_timestamp': policyAcceptance.consentTimestamp?.toIso8601String(),
            'created_at': policyAcceptance.createdAt.toIso8601String(),
            'updated_at': policyAcceptance.updatedAt.toIso8601String(),
            'last_sync_at': policyAcceptance.lastSyncAt?.toIso8601String(),
            'is_synced': policyAcceptance.isSynced,
            'marked_for_deletion': policyAcceptance.markedForDeletion,
          };
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при экспорте согласий: $e');
      }

      // 6. Лимиты использования
      debugPrint('📊 Экспортируем лимиты использования...');
      try {
        final usageLimits = await _isarService.getUserUsageLimitsByUserId(userId);
        if (usageLimits != null) {
          exportData['usage_limits'] = {
            'budget_notes_count': usageLimits.budgetNotesCount,
            'expenses_count': usageLimits.expensesCount,
            'marker_maps_count': usageLimits.markerMapsCount,
            'notes_count': usageLimits.notesCount,
            'trips_count': usageLimits.tripsCount,
            'last_reset_date': usageLimits.lastResetDate,
            'recalculated_at': usageLimits.recalculatedAt,
            'recalculation_type': usageLimits.recalculationType,
            'created_at': usageLimits.createdAt.toIso8601String(),
            'updated_at': usageLimits.updatedAt.toIso8601String(),
            'last_sync_at': usageLimits.lastSyncAt?.toIso8601String(),
            'is_synced': usageLimits.isSynced,
            'marked_for_deletion': usageLimits.markedForDeletion,
          };
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка при экспорте лимитов: $e');
      }

      debugPrint('✅ Все данные собраны успешно');
      debugPrint('📊 Статистика экспорта:');
      debugPrint('   🎣 Заметки рыбалки: ${exportData['fishing_notes']['count']}');
      debugPrint('   🗺️ Маркерные карты: ${exportData['marker_maps']['count']}');
      debugPrint('   💰 Заметки бюджета: ${exportData['budget_notes']['count']}');

      return exportData;
    } catch (e) {
      debugPrint('❌ Ошибка при сборе данных: $e');
      rethrow;
    }
  }

  /// Создание ZIP архива с данными
  Future<File?> _createZipArchive(Map<String, dynamic> exportData, String userId, [Map<String, String>? localizations]) async {
    try {
      debugPrint('📦 Создаем ZIP архив...');

      final archive = Archive();

      // Основной JSON файл с данными
      final jsonData = jsonEncode(exportData);
      final jsonBytes = utf8.encode(jsonData);
      archive.addFile(ArchiveFile('user_data.json', jsonBytes.length, jsonBytes));

      // README файл с информацией об экспорте
      final readmeContent = _generateReadmeContent(exportData, localizations);
      final readmeBytes = utf8.encode(readmeContent);
      archive.addFile(ArchiveFile('README.txt', readmeBytes.length, readmeBytes));

      // CSV файлы для удобного просмотра
      await _addCsvFiles(archive, exportData);

      // Кодируем архив
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        debugPrint('❌ Ошибка при создании ZIP архива');
        return null;
      }

      // Сохраняем файл
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'drift_notes_export_${userId.substring(0, 8)}_$timestamp.zip';
      final zipFile = File('${tempDir.path}/$fileName');

      await zipFile.writeAsBytes(zipBytes);

      debugPrint('✅ ZIP архив создан: ${zipFile.path}');
      debugPrint('📏 Размер архива: ${(zipBytes.length / 1024).toStringAsFixed(1)} KB');

      return zipFile;
    } catch (e) {
      debugPrint('❌ Ошибка при создании ZIP архива: $e');
      return null;
    }
  }

  /// Добавление CSV файлов в архив
  Future<void> _addCsvFiles(Archive archive, Map<String, dynamic> exportData) async {
    try {
      // CSV с заметками рыбалки
      if (exportData['fishing_notes'] != null) {
        final fishingCsv = _createFishingNotesCsv(exportData['fishing_notes']['data']);
        final csvBytes = utf8.encode(fishingCsv);
        archive.addFile(ArchiveFile('fishing_notes.csv', csvBytes.length, csvBytes));
      }

      // CSV с маркерными картами
      if (exportData['marker_maps'] != null) {
        final mapsCsv = _createMarkerMapsCsv(exportData['marker_maps']['data']);
        final csvBytes = utf8.encode(mapsCsv);
        archive.addFile(ArchiveFile('marker_maps.csv', csvBytes.length, csvBytes));
      }

      // CSV с заметками бюджета
      if (exportData['budget_notes'] != null) {
        final budgetCsv = _createBudgetNotesCsv(exportData['budget_notes']['data']);
        final csvBytes = utf8.encode(budgetCsv);
        archive.addFile(ArchiveFile('budget_notes.csv', csvBytes.length, csvBytes));

        // Дополнительный CSV с детальными расходами
        final expensesCsv = _createExpensesCsv(exportData['budget_notes']['data']);
        final expensesCsvBytes = utf8.encode(expensesCsv);
        archive.addFile(ArchiveFile('expenses_detailed.csv', expensesCsvBytes.length, expensesCsvBytes));
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка при создании CSV файлов: $e');
    }
  }

  /// Создание CSV для заметок рыбалки
  String _createFishingNotesCsv(List<dynamic> notes) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Date,End Date,Multi-Day,Location,Fishing Type,Temperature,Weather Condition,Tackle,Photos Count,Bite Records Count,Created At');

    for (final note in notes) {
      buffer.writeln([
        note['id'],
        _escapeCsvField(note['title'] ?? ''),
        note['date'] ?? '',
        note['end_date'] ?? '',
        note['is_multi_day'] ?? false,
        _escapeCsvField(note['location'] ?? ''),
        note['fishing_type'] ?? '',
        note['weather_data']?['temperature'] ?? '',
        note['weather_data']?['condition'] ?? '',
        _escapeCsvField(note['tackle'] ?? ''),
        (note['photo_urls'] as List?)?.length ?? 0,
        (note['bite_records'] as List?)?.length ?? 0,
        note['created_at'] ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Создание CSV для маркерных карт
  String _createMarkerMapsCsv(List<dynamic> maps) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Date,Sector,Markers Count,Attached Notes,Created At');

    for (final map in maps) {
      buffer.writeln([
        map['id'],
        _escapeCsvField(map['name'] ?? ''),
        map['date'] ?? '',
        _escapeCsvField(map['sector'] ?? ''),
        map['markers_count'] ?? 0,
        _escapeCsvField(map['attached_notes_text'] ?? ''),
        map['created_at'] ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Создание CSV для заметок бюджета
  String _createBudgetNotesCsv(List<dynamic> notes) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,End Date,Multi-Day,Location,Total Amount,Currency,Expense Count,Notes,Created At');

    for (final note in notes) {
      buffer.writeln([
        note['id'],
        note['date'] ?? '',
        note['end_date'] ?? '',
        note['is_multi_day'] ?? false,
        _escapeCsvField(note['location_name'] ?? ''),
        note['total_amount'] ?? 0,
        note['currency'] ?? '',
        note['expense_count'] ?? 0,
        _escapeCsvField(note['notes'] ?? ''),
        note['created_at'] ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Создание детального CSV для всех расходов
  String _createExpensesCsv(List<dynamic> budgetNotes) {
    final buffer = StringBuffer();
    buffer.writeln('Budget Note ID,Trip Location,Expense ID,Category,Description,Amount,Currency,Date,Location Name,Notes,Created At');

    for (final note in budgetNotes) {
      final expenses = note['expenses'] as List<dynamic>? ?? [];
      for (final expense in expenses) {
        buffer.writeln([
          note['id'],
          _escapeCsvField(note['location_name'] ?? ''),
          expense['id'] ?? '',
          expense['category'] ?? '',
          _escapeCsvField(expense['description'] ?? ''),
          expense['amount'] ?? 0,
          expense['currency'] ?? '',
          expense['date'] ?? '',
          _escapeCsvField(expense['location_name'] ?? ''),
          _escapeCsvField(expense['notes'] ?? ''),
          expense['created_at'] ?? '',
        ].join(','));
      }
    }

    return buffer.toString();
  }

  /// Экранирование полей CSV
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Генерация README файла с локализацией
  String _generateReadmeContent(Map<String, dynamic> exportData, [Map<String, String>? localizations]) {
    final l = localizations ?? {};
    final buffer = StringBuffer();
    final exportInfo = exportData['export_info'];

    buffer.writeln('===========================================');
    buffer.writeln('        ${l['readme_title'] ?? 'DRIFT NOTES - ЭКСПОРТ ДАННЫХ'}      ');
    buffer.writeln('===========================================');
    buffer.writeln('');
    buffer.writeln('${l['readme_export_date'] ?? 'Дата экспорта:'} ${exportInfo['export_date']}');
    buffer.writeln('${l['readme_user_id'] ?? 'ID пользователя:'} ${exportInfo['user_id']}');
    buffer.writeln('${l['readme_app_version'] ?? 'Версия приложения:'} ${exportInfo['app_version']}');
    buffer.writeln('${l['readme_export_version'] ?? 'Версия экспорта:'} ${exportInfo['export_version']}');
    buffer.writeln('');
    buffer.writeln('${l['readme_archive_contents'] ?? 'СОДЕРЖИМОЕ АРХИВА:'}');
    buffer.writeln('------------------');
    buffer.writeln('📄 user_data.json - ${l['readme_full_data'] ?? 'Полные данные в JSON формате'}');
    if (exportData['fishing_notes'] != null) {
      buffer.writeln('🎣 fishing_notes.csv - ${l['readme_fishing_notes'] ?? 'Заметки рыбалки'} (${exportData['fishing_notes']['count']} ${l['readme_records'] ?? 'записей'})');
    }
    if (exportData['marker_maps'] != null) {
      buffer.writeln('🗺️ marker_maps.csv - ${l['readme_marker_maps'] ?? 'Маркерные карты'} (${exportData['marker_maps']['count']} ${l['readme_records'] ?? 'записей'})');
    }
    if (exportData['budget_notes'] != null) {
      buffer.writeln('💰 budget_notes.csv - ${l['readme_budget_notes'] ?? 'Заметки бюджета'} (${exportData['budget_notes']['count']} ${l['readme_records'] ?? 'записей'})');
      buffer.writeln('🧾 expenses_detailed.csv - ${l['readme_detailed_expenses'] ?? 'Детальные расходы по всем поездкам'}');
    }
    buffer.writeln('📖 README.txt - ${l['readme_description_file'] ?? 'Этот файл с описанием'}');
    buffer.writeln('');
    buffer.writeln('${l['readme_rights_gdpr'] ?? 'ПРАВА И GDPR:'}');
    buffer.writeln('-------------');
    buffer.writeln('${l['readme_contains_all_data'] ?? 'Этот архив содержит ВСЕ ваши данные из приложения Drift Notes.'}');
    buffer.writeln('${l['readme_gdpr_compliance'] ?? 'Данные экспортированы в соответствии с требованиями GDPR.'}');
    buffer.writeln('${l['readme_data_usage'] ?? 'Вы можете использовать эти данные для переноса в другие приложения или для долгосрочного хранения.'}');
    buffer.writeln('');
    buffer.writeln('${l['readme_technical_info'] ?? 'ТЕХНИЧЕСКАЯ ИНФОРМАЦИЯ:'}');
    buffer.writeln('----------------------');
    buffer.writeln('${l['readme_json_description'] ?? '• JSON файл содержит структурированные данные со всеми полями'}');
    buffer.writeln('${l['readme_csv_description'] ?? '• CSV файлы содержат основные поля для удобного просмотра'}');
    buffer.writeln('${l['readme_date_format'] ?? '• Даты указаны в формате ISO 8601 (YYYY-MM-DDTHH:mm:ss.sssZ)'}');
    buffer.writeln('${l['readme_coordinates_format'] ?? '• Координаты указаны в десятичных градусах (WGS84)'}');
    buffer.writeln('');
    buffer.writeln('${l['readme_contact'] ?? 'Контакт:'} support@driftnotesapp.com');
    buffer.writeln('${l['readme_website'] ?? 'Сайт:'} https://driftnotesapp.com');

    return buffer.toString();
  }

  /// Запрос разрешения на запись в хранилище (удален - не нужен для Share)
  // Метод удален - используем только Share

  /// Сохранение или отправка файла (упрощенная версия - только Share)
  Future<void> _saveOrShareFile(File zipFile) async {
    try {
      // Всегда используем Share - проще и надежнее
      await Share.shareXFiles(
          [XFile(zipFile.path)],
          text: 'Экспорт данных Drift Notes',
          subject: 'Мои данные из Drift Notes'
      );
      debugPrint('✅ Файл отправлен через Share');
    } catch (e) {
      debugPrint('⚠️ Ошибка при отправке файла: $e');
      rethrow;
    }
  }
}