// Путь: lib/services/fishing_diary_share/fishing_diary_sharing_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../models/fishing_diary_model.dart';
import '../../localization/app_localizations.dart';
import '../../constants/app_constants.dart';

class FishingDiarySharingService {
  static const String _fileExtension = '.driftnotes'; // DriftNotes format
  static const String _mimeType = 'application/driftnotes';
  static const int _currentVersion = 1;

  // Метаданные файла
  static const String _appName = 'Fishing Buddy';
  static const String _fileFormatName = 'DriftNotes Fishing Diary';

  /// 🚀 ЭКСПОРТ: Создание и отправка файла записи дневника
  static Future<bool> exportDiaryEntry({
    required FishingDiaryModel diaryEntry,
    required BuildContext context,
  }) async {
    try {
      debugPrint('📤 Начинаем экспорт записи дневника: ${diaryEntry.title}');

      // 1. Создаем данные для экспорта
      final exportData = _createExportData(diaryEntry);

      // 2. Конвертируем в JSON
      final jsonString = json.encode(exportData);
      final bytes = utf8.encode(jsonString);

      // 3. Создаем временный файл
      final tempDir = await getTemporaryDirectory();
      final fileName = _sanitizeFileName(diaryEntry.title) + _fileExtension;
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(bytes);

      debugPrint('✅ Файл создан: ${file.path}');

      // 4. Отправляем через системное меню "Поделиться"
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: AppLocalizations.of(context).translate('share_diary_entry_text')
            .replaceAll('{entryName}', diaryEntry.title),
        subject: '${AppLocalizations.of(context).translate('fishing_diary_entry')}: ${diaryEntry.title}',
      );

      debugPrint('📤 Результат отправки: ${result.status}');

      // 5. Удаляем временный файл через небольшую задержку
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Временный файл удален');
          }
        } catch (e) {
          debugPrint('⚠️ Не удалось удалить временный файл: $e');
        }
      });

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('❌ Ошибка экспорта: $e');
      return false;
    }
  }

  /// 🔍 ИМПОРТ: Парсинг файла записи дневника
  static Future<DiaryImportResult> parseDiaryEntryFile(String filePath) async {
    try {
      debugPrint('📥 Начинаем парсинг файла: $filePath');

      // 1. Читаем файл
      final file = File(filePath);
      if (!await file.exists()) {
        return DiaryImportResult.error('Файл не найден');
      }

      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);

      // 2. Парсим JSON
      final Map<String, dynamic> data = json.decode(jsonString);

      // 3. Валидируем структуру файла
      final validation = _validateImportData(data);
      if (!validation.isValid) {
        return DiaryImportResult.error(validation.error ?? 'Неверный формат файла');
      }

      // 4. Извлекаем данные записи
      final entryData = data['diaryData'] as Map<String, dynamic>;

      // 5. Создаем модель записи с новым ID
      final newId = const Uuid().v4();
      final diaryEntry = FishingDiaryModel.fromJson({
        ...entryData,
        'id': newId,
      });

      debugPrint('✅ Файл успешно распарсен: ${diaryEntry.title}');

      return DiaryImportResult.success(
        diaryEntry: diaryEntry,
        originalFileName: data['metadata']['originalFileName'] ?? 'unknown',
        exportDate: DateTime.tryParse(data['metadata']['exportDate'] ?? '') ?? DateTime.now(),
        entriesCount: 1, // Одна запись
      );
    } catch (e) {
      debugPrint('❌ Ошибка парсинга файла: $e');
      return DiaryImportResult.error('Ошибка чтения файла: $e');
    }
  }

  /// 📊 ИМПОРТ: Интеграция записи в базу пользователя
  static Future<bool> importDiaryEntry({
    required FishingDiaryModel diaryEntry,
    required Function(FishingDiaryModel) onImport,
  }) async {
    try {
      debugPrint('💾 Импортируем запись в базу: ${diaryEntry.title}');

      // Вызываем callback для сохранения через Repository
      await onImport(diaryEntry);

      debugPrint('✅ Запись успешно импортирована');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка импорта записи: $e');
      return false;
    }
  }

  /// 🏗️ Создание данных для экспорта
  static Map<String, dynamic> _createExportData(FishingDiaryModel diaryEntry) {
    return {
      'fileFormat': _fileFormatName,
      'version': _currentVersion,
      'metadata': {
        'appName': _appName,
        'exportDate': DateTime.now().toIso8601String(),
        'originalFileName': _sanitizeFileName(diaryEntry.title),
        'entriesCount': 1,
      },
      'diaryData': {
        // Исключаем userId для безопасности
        'title': diaryEntry.title,
        'description': diaryEntry.description,
        'isFavorite': diaryEntry.isFavorite,
        'createdAt': diaryEntry.createdAt.millisecondsSinceEpoch,
        'updatedAt': diaryEntry.updatedAt.millisecondsSinceEpoch,
      },
    };
  }

  /// ✅ Валидация данных импорта
  static ValidationResult _validateImportData(Map<String, dynamic> data) {
    try {
      // Проверяем обязательные поля
      if (!data.containsKey('fileFormat') || data['fileFormat'] != _fileFormatName) {
        return ValidationResult(false, 'Неподдерживаемый формат файла');
      }

      if (!data.containsKey('version')) {
        return ValidationResult(false, 'Отсутствует версия файла');
      }

      final version = data['version'] as int?;
      if (version == null || version > _currentVersion) {
        return ValidationResult(false, 'Неподдерживаемая версия файла');
      }

      if (!data.containsKey('diaryData')) {
        return ValidationResult(false, 'Отсутствуют данные записи');
      }

      final diaryData = data['diaryData'] as Map<String, dynamic>?;
      if (diaryData == null) {
        return ValidationResult(false, 'Некорректные данные записи');
      }

      // Проверяем обязательные поля записи
      if (!diaryData.containsKey('title') || (diaryData['title'] as String?)?.trim().isEmpty == true) {
        return ValidationResult(false, 'Отсутствует название записи');
      }

      if (!diaryData.containsKey('createdAt') && !diaryData.containsKey('updatedAt')) {
        return ValidationResult(false, 'Отсутствуют даты записи');
      }

      return ValidationResult(true);
    } catch (e) {
      return ValidationResult(false, 'Ошибка валидации: $e');
    }
  }

  /// 🧹 Очистка названия файла от недопустимых символов
  static String _sanitizeFileName(String fileName) {
    // Удаляем недопустимые символы для имени файла
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }
}

/// 📊 Результат операции импорта записи дневника
class DiaryImportResult {
  final bool isSuccess;
  final FishingDiaryModel? diaryEntry;
  final String? error;
  final String? originalFileName;
  final DateTime? exportDate;
  final int? entriesCount;

  DiaryImportResult.success({
    required this.diaryEntry,
    this.originalFileName,
    this.exportDate,
    this.entriesCount,
  }) : isSuccess = true, error = null;

  DiaryImportResult.error(this.error)
      : isSuccess = false,
        diaryEntry = null,
        originalFileName = null,
        exportDate = null,
        entriesCount = null;
}

/// ✅ Результат валидации
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult(this.isValid, [this.error]);
}