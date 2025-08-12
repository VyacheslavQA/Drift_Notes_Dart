// Путь: lib/services/file_handler/driftnotes_file_handler.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/marker_map_share/marker_map_share_service.dart';
import '../../services/fishing_diary_share/fishing_diary_sharing_service.dart';
import '../../screens/marker_maps/marker_map_import_preview_screen.dart';
import '../../screens/fishing_diary/fishing_diary_import_preview_screen.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../../localization/app_localizations.dart';

class DriftNotesFileHandler {
  // Поддерживаемые форматы файлов
  static const String _markerMapFormat = 'DriftNotes Marker Map';
  static const String _fishingDiaryFormat = 'DriftNotes Fishing Diary';

  /// 🚀 УНИВЕРСАЛЬНЫЙ ОБРАБОТЧИК: Определяет тип файла и обрабатывает его
  static Future<void> handleDriftNotesFile(BuildContext context, String filePath) async {
    debugPrint('🔍 handleDriftNotesFile: Начинаем обработку файла $filePath');

    try {
      // 1. Определяем тип файла
      final fileType = await _detectFileType(filePath);
      debugPrint('📋 Тип файла: $fileType');

      if (fileType == null) {
        debugPrint('❌ Неподдерживаемый формат файла');
        _showErrorMessage(context, 'Неподдерживаемый формат файла');
        return;
      }

      // 2. Проверяем Premium статус
      debugPrint('🔒 Проверяем Premium статус...');
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final hasPremium = subscriptionProvider.hasPremiumAccess;
      debugPrint('🔒 Premium статус: $hasPremium');

      if (!hasPremium) {
        debugPrint('❌ Нет Premium - показываем PaywallScreen');
        await _showPaywallForFileType(context, fileType);
        return;
      }

      // 3. Обрабатываем файл в зависимости от типа
      switch (fileType) {
        case DriftNotesFileType.markerMap:
          await _handleMarkerMapFile(context, filePath);
          break;
        case DriftNotesFileType.fishingDiary:
          await _handleFishingDiaryFile(context, filePath);
          break;
      }

    } catch (e) {
      debugPrint('❌ Критическая ошибка обработки файла: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      if (context.mounted) {
        _showErrorMessage(context, 'Ошибка обработки файла: $e');
      }
    }
  }

  /// 🔍 ОПРЕДЕЛЕНИЕ ТИПА: Анализирует содержимое файла
  static Future<DriftNotesFileType?> _detectFileType(String filePath) async {
    try {
      debugPrint('📄 Читаем файл для определения типа: $filePath');

      // Читаем файл
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ Файл не найден: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);

      // Парсим JSON
      final Map<String, dynamic> data = json.decode(jsonString);

      // Проверяем поле fileFormat
      final fileFormat = data['fileFormat'] as String?;
      debugPrint('📋 Обнаружен fileFormat: $fileFormat');

      switch (fileFormat) {
        case _markerMapFormat:
          return DriftNotesFileType.markerMap;
        case _fishingDiaryFormat:
          return DriftNotesFileType.fishingDiary;
        default:
          debugPrint('❌ Неизвестный формат файла: $fileFormat');
          return null;
      }
    } catch (e) {
      debugPrint('❌ Ошибка определения типа файла: $e');
      return null;
    }
  }

  /// 🗺️ ОБРАБОТКА МАРКЕРНОЙ КАРТЫ
  static Future<void> _handleMarkerMapFile(BuildContext context, String filePath) async {
    debugPrint('🗺️ Обрабатываем файл маркерной карты...');

    try {
      // Парсим файл маркерной карты
      final importResult = await MarkerMapShareService.parseMarkerMapFile(filePath);
      debugPrint('✅ Результат парсинга маркерной карты: success=${importResult.isSuccess}');

      if (!importResult.isSuccess || importResult.markerMap == null) {
        debugPrint('❌ Ошибка парсинга маркерной карты: ${importResult.error}');
        if (context.mounted) {
          _showErrorMessage(context, importResult.error ?? 'Ошибка импорта маркерной карты');
        }
        return;
      }

      // Переходим к экрану превью маркерной карты
      debugPrint('🚀 Переходим к превью маркерной карты...');
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkerMapImportPreviewScreen(
              importResult: importResult,
              sourceFilePath: filePath,
            ),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Ошибка обработки маркерной карты: $e');
      if (context.mounted) {
        _showErrorMessage(context, 'Ошибка импорта маркерной карты: $e');
      }
    }
  }

  /// 📔 ОБРАБОТКА ЗАПИСИ ДНЕВНИКА
  static Future<void> _handleFishingDiaryFile(BuildContext context, String filePath) async {
    debugPrint('📔 Обрабатываем файл записи дневника...');

    try {
      // Парсим файл записи дневника
      final importResult = await FishingDiarySharingService.parseDiaryEntryFile(filePath);
      debugPrint('✅ Результат парсинга записи дневника: success=${importResult.isSuccess}');

      if (!importResult.isSuccess || importResult.diaryEntry == null) {
        debugPrint('❌ Ошибка парсинга записи дневника: ${importResult.error}');
        if (context.mounted) {
          _showErrorMessage(context, importResult.error ?? 'Ошибка импорта записи дневника');
        }
        return;
      }

      // Переходим к экрану превью записи дневника
      debugPrint('🚀 Переходим к превью записи дневника...');
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FishingDiaryImportPreviewScreen(
              importResult: importResult,
              sourceFilePath: filePath,
            ),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Ошибка обработки записи дневника: $e');
      if (context.mounted) {
        _showErrorMessage(context, 'Ошибка импорта записи дневника: $e');
      }
    }
  }

  /// 💳 ПОКАЗ PAYWALL В ЗАВИСИМОСТИ ОТ ТИПА ФАЙЛА
  static Future<void> _showPaywallForFileType(BuildContext context, DriftNotesFileType fileType) async {
    String contentType;
    String blockedFeature;

    switch (fileType) {
      case DriftNotesFileType.markerMap:
        contentType = 'marker_map_sharing';
        blockedFeature = 'Импорт маркерных карт';
        break;
      case DriftNotesFileType.fishingDiary:
        contentType = 'fishing_diary_sharing';
        blockedFeature = 'Импорт записей дневника';
        break;
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaywallScreen(
            contentType: contentType,
            blockedFeature: blockedFeature,
          ),
        ),
      );
    }
  }

  /// ❌ ПОКАЗ СООБЩЕНИЯ ОБ ОШИБКЕ
  static void _showErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 📊 ПОЛУЧЕНИЕ ИНФОРМАЦИИ О ФАЙЛЕ (без импорта)
  static Future<DriftNotesFileInfo?> getFileInfo(String filePath) async {
    try {
      debugPrint('📊 Получаем информацию о файле: $filePath');

      final fileType = await _detectFileType(filePath);
      if (fileType == null) {
        return null;
      }

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      final metadata = data['metadata'] as Map<String, dynamic>?;
      final version = data['version'] as int?;

      return DriftNotesFileInfo(
        fileType: fileType,
        version: version ?? 1,
        originalFileName: metadata?['originalFileName'],
        exportDate: metadata?['exportDate'] != null
            ? DateTime.tryParse(metadata!['exportDate'])
            : null,
        appName: metadata?['appName'],
      );

    } catch (e) {
      debugPrint('❌ Ошибка получения информации о файле: $e');
      return null;
    }
  }
}

/// 📂 ТИПЫ ФАЙЛОВ DRIFTNOTES
enum DriftNotesFileType {
  markerMap,
  fishingDiary,
}

/// 📊 ИНФОРМАЦИЯ О ФАЙЛЕ DRIFTNOTES
class DriftNotesFileInfo {
  final DriftNotesFileType fileType;
  final int version;
  final String? originalFileName;
  final DateTime? exportDate;
  final String? appName;

  DriftNotesFileInfo({
    required this.fileType,
    required this.version,
    this.originalFileName,
    this.exportDate,
    this.appName,
  });

  /// 📝 Получить читаемое название типа файла
  String getFileTypeName() {
    switch (fileType) {
      case DriftNotesFileType.markerMap:
        return 'Маркерная карта';
      case DriftNotesFileType.fishingDiary:
        return 'Запись дневника';
    }
  }

  /// 🎯 Получить иконку для типа файла
  IconData getFileTypeIcon() {
    switch (fileType) {
      case DriftNotesFileType.markerMap:
        return Icons.map;
      case DriftNotesFileType.fishingDiary:
        return Icons.book;
    }
  }
}