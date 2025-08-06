// Путь: lib/services/marker_map_share/marker_map_share_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../models/marker_map_model.dart';
import '../../localization/app_localizations.dart';
import '../../constants/app_constants.dart';

class MarkerMapShareService {
  static const String _fileExtension = '.fmm'; // Fishing Marker Map
  static const String _mimeType = 'application/octet-stream';
  static const int _currentVersion = 1;

  // Метаданные файла
  static const String _appName = 'Fishing Buddy';
  static const String _fileFormatName = 'Fishing Marker Map';

  /// 🚀 ЭКСПОРТ: Создание и отправка файла маркерной карты
  static Future<bool> exportMarkerMap({
    required MarkerMapModel markerMap,
    required BuildContext context,
  }) async {
    try {
      debugPrint('📤 Начинаем экспорт маркерной карты: ${markerMap.name}');

      // 1. Создаем данные для экспорта
      final exportData = _createExportData(markerMap);

      // 2. Конвертируем в JSON
      final jsonString = json.encode(exportData);
      final bytes = utf8.encode(jsonString);

      // 3. Создаем временный файл
      final tempDir = await getTemporaryDirectory();
      final fileName = _sanitizeFileName(markerMap.name) + _fileExtension;
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(bytes);

      debugPrint('✅ Файл создан: ${file.path}');

      // 4. Отправляем через системное меню "Поделиться"
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: AppLocalizations.of(context).translate('share_marker_map_text')
            .replaceAll('{mapName}', markerMap.name),
        subject: '${AppLocalizations.of(context).translate('marker_map')}: ${markerMap.name}',
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

  /// 🔍 ИМПОРТ: Парсинг файла маркерной карты
  static Future<ImportResult> parseMarkerMapFile(String filePath) async {
    try {
      debugPrint('📥 Начинаем парсинг файла: $filePath');

      // 1. Читаем файл
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult.error('Файл не найден');
      }

      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(bytes);

      // 2. Парсим JSON
      final Map<String, dynamic> data = json.decode(jsonString);

      // 3. Валидируем структуру файла
      final validation = _validateImportData(data);
      if (!validation.isValid) {
        return ImportResult.error(validation.error ?? 'Неверный формат файла');
      }

      // 4. Извлекаем данные карты
      final mapData = data['mapData'] as Map<String, dynamic>;

      // 5. Создаем модель карты с новым ID
      final newId = const Uuid().v4();
      final markerMap = MarkerMapModel.fromJson({
        ...mapData,
        'id': newId,
      });

      debugPrint('✅ Файл успешно распарсен: ${markerMap.name}');

      return ImportResult.success(
        markerMap: markerMap,
        originalFileName: data['metadata']['originalFileName'] ?? 'unknown',
        exportDate: DateTime.tryParse(data['metadata']['exportDate'] ?? '') ?? DateTime.now(),
        markersCount: markerMap.markers.length,
      );
    } catch (e) {
      debugPrint('❌ Ошибка парсинга файла: $e');
      return ImportResult.error('Ошибка чтения файла: $e');
    }
  }

  /// 📊 ИМПОРТ: Интеграция карты в базу пользователя
  static Future<bool> importMarkerMap({
    required MarkerMapModel markerMap,
    required Function(MarkerMapModel) onImport,
  }) async {
    try {
      debugPrint('💾 Импортируем карту в базу: ${markerMap.name}');

      // Вызываем callback для сохранения через Repository
      await onImport(markerMap);

      debugPrint('✅ Карта успешно импортирована');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка импорта карты: $e');
      return false;
    }
  }

  /// 🏗️ Создание данных для экспорта
  static Map<String, dynamic> _createExportData(MarkerMapModel markerMap) {
    return {
      'fileFormat': _fileFormatName,
      'version': _currentVersion,
      'metadata': {
        'appName': _appName,
        'exportDate': DateTime.now().toIso8601String(),
        'originalFileName': _sanitizeFileName(markerMap.name),
        'markersCount': markerMap.markers.length,
      },
      'mapData': {
        // Исключаем userId для безопасности
        'name': markerMap.name,
        'date': markerMap.date.millisecondsSinceEpoch,
        'sector': markerMap.sector,
        'markers': markerMap.markers.map((marker) {
          // Очищаем маркеры от служебных данных
          final cleanMarker = Map<String, dynamic>.from(marker);
          cleanMarker.remove('_hitboxCenter');
          cleanMarker.remove('_hitboxRadius');
          return cleanMarker;
        }).toList(),
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

      if (!data.containsKey('mapData')) {
        return ValidationResult(false, 'Отсутствуют данные карты');
      }

      final mapData = data['mapData'] as Map<String, dynamic>?;
      if (mapData == null) {
        return ValidationResult(false, 'Некорректные данные карты');
      }

      // Проверяем обязательные поля карты
      if (!mapData.containsKey('name') || (mapData['name'] as String?)?.trim().isEmpty == true) {
        return ValidationResult(false, 'Отсутствует название водоема');
      }

      if (!mapData.containsKey('date')) {
        return ValidationResult(false, 'Отсутствует дата карты');
      }

      if (!mapData.containsKey('markers')) {
        return ValidationResult(false, 'Отсутствуют маркеры');
      }

      // Проверяем маркеры
      final markers = mapData['markers'] as List?;
      if (markers == null) {
        return ValidationResult(false, 'Некорректные данные маркеров');
      }

      // Валидируем каждый маркер
      for (final marker in markers) {
        if (marker is! Map<String, dynamic>) {
          return ValidationResult(false, 'Некорректный формат маркера');
        }

        final markerMap = marker as Map<String, dynamic>;
        if (!markerMap.containsKey('id') ||
            !markerMap.containsKey('rayIndex') ||
            !markerMap.containsKey('distance')) {
          return ValidationResult(false, 'Отсутствуют обязательные данные маркера');
        }
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

/// 📊 Результат операции импорта
class ImportResult {
  final bool isSuccess;
  final MarkerMapModel? markerMap;
  final String? error;
  final String? originalFileName;
  final DateTime? exportDate;
  final int? markersCount;

  ImportResult.success({
    required this.markerMap,
    this.originalFileName,
    this.exportDate,
    this.markersCount,
  }) : isSuccess = true, error = null;

  ImportResult.error(this.error)
      : isSuccess = false,
        markerMap = null,
        originalFileName = null,
        exportDate = null,
        markersCount = null;
}

/// ✅ Результат валидации
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult(this.isValid, [this.error]);
}