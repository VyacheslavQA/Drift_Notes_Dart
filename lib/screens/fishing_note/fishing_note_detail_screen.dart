// Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../models/marker_map_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../repositories/marker_map_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_overlay.dart';
import '../../localization/app_localizations.dart';
import 'photo_gallery_screen.dart';
import 'bite_records_section.dart';
import 'cover_photo_selection_screen.dart';
import '../../screens/fishing_note/edit_fishing_note_screen.dart';
import '../marker_maps/marker_map_screen.dart';
import '../map/map_location_screen.dart';
import '../../widgets/fishing_photo_grid.dart';
import '../../models/ai_bite_prediction_model.dart';
import '../../services/ai_bite_prediction_service.dart';
import '../../services/weather_settings_service.dart';

class FishingNoteDetailScreen extends StatefulWidget {
  final String noteId;

  const FishingNoteDetailScreen({super.key, required this.noteId});

  @override
  State<FishingNoteDetailScreen> createState() =>
      _FishingNoteDetailScreenState();
}

class _FishingNoteDetailScreenState extends State<FishingNoteDetailScreen> {
  final _fishingNoteRepository = FishingNoteRepository();
  final _markerMapRepository = MarkerMapRepository();
  final _weatherSettings = WeatherSettingsService();

  FishingNoteModel? _note;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Список маркерных карт, привязанных к этой заметке
  List<MarkerMapModel> _linkedMarkerMaps = [];
  bool _isLoadingMarkerMaps = false;

  // ИИ-анализ
  AIBitePrediction? _aiPrediction;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = await _fishingNoteRepository.getFishingNoteById(
        widget.noteId,
      );

      if (mounted) {
        setState(() {
          _note = note;
          _isLoading = false;
        });

        // Загружаем ИИ-анализ из заметки, если он есть
        _loadAIFromNote();

        // После загрузки заметки загружаем связанные маркерные карты
        _loadLinkedMarkerMaps();
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() {
          _errorMessage = '${localizations.translate('error_loading')}: $e';
          _isLoading = false;
        });
      }
    }
  }

  // НОВЫЙ МЕТОД: Загрузка ИИ-анализа из сохраненных данных
  void _loadAIFromNote() {
    if (_note?.aiPrediction == null) return;

    try {
      final aiMap = _note!.aiPrediction!;
      final activityLevelString =
          aiMap['activityLevel'] as String? ?? 'moderate';
      ActivityLevel activityLevel = ActivityLevel.moderate;

      switch (activityLevelString.split('.').last) {
        case 'excellent':
          activityLevel = ActivityLevel.excellent;
          break;
        case 'good':
          activityLevel = ActivityLevel.good;
          break;
        case 'moderate':
          activityLevel = ActivityLevel.moderate;
          break;
        case 'poor':
          activityLevel = ActivityLevel.poor;
          break;
        case 'veryPoor':
          activityLevel = ActivityLevel.veryPoor;
          break;
      }

      _aiPrediction = AIBitePrediction(
        overallScore: aiMap['overallScore'] as int? ?? 50,
        activityLevel: activityLevel,
        confidence: (aiMap['confidencePercent'] as int? ?? 50) / 100.0,
        recommendation: aiMap['recommendation'] as String? ?? '',
        tips: List<String>.from(aiMap['tips'] ?? []),
        fishingType: aiMap['fishingType'] as String? ?? _note!.fishingType,
      );

      debugPrint(
        '🧠 ИИ-анализ загружен из заметки: ${_aiPrediction!.overallScore} баллов',
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ИИ-анализа: $e');
    }
  }

  // Метод для загрузки связанных маркерных карт
  Future<void> _loadLinkedMarkerMaps() async {
    if (_note == null) return;

    setState(() {
      _isLoadingMarkerMaps = true;
    });

    try {
      // Получаем все маркерные карты пользователя
      final allMaps = await _markerMapRepository.getUserMarkerMaps();

      // Фильтруем только те, которые привязаны к текущей заметке
      final linkedMaps =
      allMaps.where((map) => map.noteIds.contains(_note!.id)).toList();

      if (mounted) {
        setState(() {
          _linkedMarkerMaps = linkedMaps;
          _isLoadingMarkerMaps = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке маркерных карт: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarkerMaps = false;
        });
      }
    }
  }

  // НОВЫЙ МЕТОД: Открытие карты с местом рыбалки
  Future<void> _showLocationOnMap() async {
    if (_note == null || (_note!.latitude == 0 && _note!.longitude == 0)) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('location_not_available')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Открываем карту с координатами места рыбалки
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationScreen(
          initialLatitude: _note!.latitude,
          initialLongitude: _note!.longitude,
        ),
      ),
    );
    // После возврата с карты ничего не делаем - просто остаемся в заметке
  }

  // НОВЫЙ МЕТОД: Построение маршрута до места рыбалки
  Future<void> _navigateToLocation() async {
    if (_note == null || (_note!.latitude == 0 && _note!.longitude == 0)) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('location_not_available')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final localizations = AppLocalizations.of(context);

    // Показываем выбор навигационных приложений
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNavigationOptionsSheet(),
    );
  }

  // НОВЫЙ МЕТОД: BottomSheet с выбором навигационных приложений
  Widget _buildNavigationOptionsSheet() {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.translate('choose_map'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppConstants.textColor),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Google Maps
          _buildNavigationOption(
            title: 'Google Maps',
            subtitle: localizations.translate('universal_navigation'),
            icon: Icons.map,
            onTap: () => _openGoogleMaps(),
          ),

          const SizedBox(height: 12),

          // Apple Maps (только для iOS)
          if (Platform.isIOS)
            _buildNavigationOption(
              title: 'Apple Maps',
              subtitle: localizations.translate('ios_navigation'),
              icon: Icons.map_outlined,
              onTap: () => _openAppleMaps(),
            ),

          if (Platform.isIOS) const SizedBox(height: 12),

          // Яндекс.Карты
          _buildNavigationOption(
            title: localizations.translate('yandex_maps'),
            subtitle: localizations.translate('detailed_russian_maps'),
            icon: Icons.alt_route,
            onTap: () => _openYandexMaps(),
          ),

          const SizedBox(height: 12),

          // 2GIS
          _buildNavigationOption(
            title: '2GIS',
            subtitle: localizations.translate('detailed_city_maps'),
            icon: Icons.location_city,
            onTap: () => _open2GIS(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // НОВЫЙ МЕТОД: Построение опции навигации
  Widget _buildNavigationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppConstants.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.launch,
              color: AppConstants.textColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // НОВЫЕ МЕТОДЫ: Открытие различных навигационных приложений
  Future<void> _openGoogleMaps() async {
    Navigator.pop(context);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_note!.latitude},${_note!.longitude}';
    await _launchURL(url, 'Google Maps');
  }

  Future<void> _openAppleMaps() async {
    Navigator.pop(context);
    final url = 'http://maps.apple.com/?daddr=${_note!.latitude},${_note!.longitude}&dirflg=d';
    await _launchURL(url, 'Apple Maps');
  }

  Future<void> _openYandexMaps() async {
    Navigator.pop(context);
    final url = 'yandexmaps://maps.yandex.ru/?rtext=~${_note!.latitude},${_note!.longitude}&rtt=auto';
    await _launchURL(url, 'Яндекс.Карты');
  }

  Future<void> _open2GIS() async {
    Navigator.pop(context);
    final url = 'dgis://2gis.ru/routeSearch/rsType/car/to/${_note!.longitude},${_note!.latitude}';
    await _launchURL(url, '2GIS');
  }

  // НОВЫЙ МЕТОД: Универсальный запуск URL
  Future<void> _launchURL(String url, String appName) async {
    final localizations = AppLocalizations.of(context);

    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Если приложение не установлено, показываем сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations.translate('app_not_installed')}: $appName',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: localizations.translate('install'),
                textColor: Colors.white,
                onPressed: () => _openAppStore(appName),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_opening_app')}: $appName',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // НОВЫЙ МЕТОД: Открытие магазина приложений
  Future<void> _openAppStore(String appName) async {
    String storeUrl = '';

    if (Platform.isAndroid) {
      switch (appName) {
        case 'Google Maps':
          storeUrl = 'https://play.google.com/store/apps/details?id=com.google.android.apps.maps';
          break;
        case 'Яндекс.Карты':
          storeUrl = 'https://play.google.com/store/apps/details?id=ru.yandex.yandexmaps';
          break;
        case '2GIS':
          storeUrl = 'https://play.google.com/store/apps/details?id=ru.dublgis.dgismobile';
          break;
      }
    } else if (Platform.isIOS) {
      switch (appName) {
        case 'Google Maps':
          storeUrl = 'https://apps.apple.com/app/google-maps/id585027354';
          break;
        case 'Яндекс.Карты':
          storeUrl = 'https://apps.apple.com/app/yandex-maps/id313877526';
          break;
        case '2GIS':
          storeUrl = 'https://apps.apple.com/app/2gis/id481627348';
          break;
      }
    }

    if (storeUrl.isNotEmpty) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // Обработчики для работы с записями о поклёвках
  Future<void> _addBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и добавляем новую запись
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords)
        ..add(record);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(biteRecords: updatedBiteRecords);

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() {
          _note = updatedNote;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('bite_record_saved')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_adding_bite')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateBiteRecord(BiteRecord record) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и обновляем запись
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords);
      final index = updatedBiteRecords.indexWhere((r) => r.id == record.id);

      if (index != -1) {
        updatedBiteRecords[index] = record;

        // Создаем обновленную модель заметки
        final updatedNote = _note!.copyWith(biteRecords: updatedBiteRecords);

        // Сохраняем в репозитории
        await _fishingNoteRepository.updateFishingNote(updatedNote);

        // Обновляем локальное состояние
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          setState(() {
            _note = updatedNote;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('bite_record_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.translate('bite_not_found')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_updating_bite')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBiteRecord(String recordId) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      // Создаем копию списка и удаляем запись
      final updatedBiteRecords = List<BiteRecord>.from(_note!.biteRecords)
        ..removeWhere((r) => r.id == recordId);

      // Создаем обновленную модель заметки
      final updatedNote = _note!.copyWith(biteRecords: updatedBiteRecords);

      // Сохраняем в репозитории
      await _fishingNoteRepository.updateFishingNote(updatedNote);

      // Обновляем локальное состояние
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() {
          _note = updatedNote;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('bite_record_deleted')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations.translate('error_deleting_bite')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Метод для перехода к просмотру маркерной карты
  void _viewMarkerMap(MarkerMapModel map) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MarkerMapScreen(markerMap: map)),
    ).then((_) {
      // Обновляем список маркерных карт после возвращения
      _loadLinkedMarkerMaps();
    });
  }

  // Метод для перехода к редактированию заметки
  Future<void> _editNote() async {
    if (_note == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFishingNoteScreen(note: _note!),
      ),
    );

    if (result == true) {
      // Перезагружаем заметку, чтобы отобразить изменения
      _loadNote();
    }
  }

  // Выбор обложки
  Future<void> _selectCoverPhoto() async {
    if (_note == null || _note!.photoUrls.isEmpty) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('first_add_photos')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CoverPhotoSelectionScreen(
          photoUrls: _note!.photoUrls,
          currentCoverPhotoUrl:
          _note!.coverPhotoUrl.isNotEmpty ? _note!.coverPhotoUrl : null,
          currentCropSettings: _note!.coverCropSettings,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      setState(() => _isSaving = true);

      try {
        // Создаем обновленную модель заметки с новой обложкой
        final updatedNote = _note!.copyWith(
          coverPhotoUrl: result['coverPhotoUrl'],
          coverCropSettings: result['cropSettings'],
        );

        // Сохраняем в репозитории
        await _fishingNoteRepository.updateFishingNote(updatedNote);

        // Обновляем локальное состояние
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          setState(() {
            _note = updatedNote;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('cover_updated_successfully'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations.translate('error_updating_cover')}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewPhotoGallery(int initialIndex) {
    if (_note == null || _note!.photoUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PhotoGalleryScreen(
          photos: _note!.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('delete_note'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('delete_note_confirmation'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(color: AppConstants.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);

        await _fishingNoteRepository.deleteFishingNote(widget.noteId);

        if (mounted) {
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('note_deleted_successfully'),
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true); // true для обновления списка заметок
        }
      } catch (e) {
        if (mounted) {
          final localizations = AppLocalizations.of(context);
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${localizations.translate('error_deleting_note')}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Метод для форматирования температуры согласно настройкам
  String _formatTemperature(double celsius) {
    final unit = _weatherSettings.temperatureUnit;
    switch (unit) {
      case TemperatureUnit.celsius:
        return '${celsius.toStringAsFixed(1)}°C';
      case TemperatureUnit.fahrenheit:
        final fahrenheit = (celsius * 9 / 5) + 32;
        return '${fahrenheit.toStringAsFixed(1)}°F';
    }
  }

  // Метод для форматирования скорости ветра согласно настройкам
  String _formatWindSpeed(double meterPerSecond) {
    final unit = _weatherSettings.windSpeedUnit;
    switch (unit) {
      case WindSpeedUnit.ms:
        return '${meterPerSecond.toStringAsFixed(1)} м/с';
      case WindSpeedUnit.kmh:
        final kmh = meterPerSecond * 3.6;
        return '${kmh.toStringAsFixed(1)} км/ч';
      case WindSpeedUnit.mph:
        final mph = meterPerSecond * 2.237;
        return '${mph.toStringAsFixed(1)} mph';
    }
  }

  // Метод для форматирования давления согласно настройкам
  String _formatPressure(double hpa) {
    final unit = _weatherSettings.pressureUnit;
    final calibration = _weatherSettings.barometerCalibration;

    // Применяем калибровку (калибровка хранится в гПа)
    final calibratedHpa = hpa + calibration;

    switch (unit) {
      case PressureUnit.hpa:
        return '${calibratedHpa.toStringAsFixed(0)} гПа';
      case PressureUnit.mmhg:
        final mmhg = calibratedHpa / 1.333;
        return '${mmhg.toStringAsFixed(0)} мм рт.ст.';
      case PressureUnit.inhg:
        final inhg = calibratedHpa / 33.8639;
        return '${inhg.toStringAsFixed(2)} inHg';
    }
  }

  // Получение цвета по скору ИИ
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  // Получение текста уровня активности
  String _getActivityLevelText(
      ActivityLevel level,
      AppLocalizations localizations,
      ) {
    switch (level) {
      case ActivityLevel.excellent:
        return localizations.translate('excellent_activity');
      case ActivityLevel.good:
        return localizations.translate('good_activity');
      case ActivityLevel.moderate:
        return localizations.translate('moderate_activity');
      case ActivityLevel.poor:
        return localizations.translate('poor_activity');
      case ActivityLevel.veryPoor:
        return localizations.translate('very_poor_activity');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _note?.title.isNotEmpty == true
              ? _note!.title
              : _note?.location ?? localizations.translate('fishing_details'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _note != null) ...[
            // Кнопка редактирования
            IconButton(
              icon: Icon(Icons.edit, color: AppConstants.textColor),
              tooltip: localizations.translate('edit'),
              onPressed: _editNote,
            ),
            // Кнопка для выбора обложки
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: localizations.translate('select_cover'),
              onPressed: _selectCoverPhoto,
            ),
            // Кнопка удаления
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: localizations.translate('delete_note'),
              onPressed: _deleteNote,
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        message:
        _isLoading
            ? localizations.translate('loading')
            : localizations.translate('saving'),
        child:
        _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadNote,
                child: Text(localizations.translate('try_again')),
              ),
            ],
          ),
        )
            : _note == null
            ? Center(
          child: Text(
            localizations.translate('bite_not_found'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
            ),
          ),
        )
            : _buildNoteDetails(),
      ),
    );
  }

  Widget _buildNoteDetails() {
    if (_note == null) return const SizedBox();

    final localizations = AppLocalizations.of(context);

    // Подсчет пойманных рыб и нереализованных поклевок
    final caughtFishCount =
        _note!.biteRecords
            .where((record) => record.fishType.isNotEmpty && record.weight > 0)
            .length;
    final missedBitesCount = _note!.biteRecords.length - caughtFishCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фотогалерея
          if (_note!.photoUrls.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(localizations.translate('photos')),
                    TextButton.icon(
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: Text(localizations.translate('view')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                      onPressed: () => _viewPhotoGallery(0),
                    ),
                  ],
                ),
                FishingPhotoGrid(
                  photoUrls: _note!.photoUrls,
                  onViewAllPressed: () => _viewPhotoGallery(0),
                ),
              ],
            ),

          // Общая информация
          _buildInfoCard(
            caughtFishCount: caughtFishCount,
            missedBitesCount: missedBitesCount,
          ),

          const SizedBox(height: 20),

          // Если есть погода, показываем её
          if (_note!.weather != null) ...[
            _buildWeatherCard(),
            const SizedBox(height: 20),
          ],

          // НОВОЕ: Отображение ИИ-анализа
          if (_aiPrediction != null) ...[
            _buildAIAnalysisCard(),
            const SizedBox(height: 20),
          ],

          // Маркерные карты
          if (_linkedMarkerMaps.isNotEmpty || _isLoadingMarkerMaps) ...[
            _buildMarkerMapsSection(),
            const SizedBox(height: 20),
          ],

          // Снасти
          if (_note!.tackle.isNotEmpty) ...[
            _buildSectionHeader(localizations.translate('tackle')),
            _buildContentCard(_note!.tackle),
            const SizedBox(height: 20),
          ],

          // Заметки
          if (_note!.notes.isNotEmpty) ...[
            _buildSectionHeader(localizations.translate('notes')),
            _buildContentCard(_note!.notes),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),

          // Поклевки
          BiteRecordsSection(
            note: _note!,
            onAddRecord: _addBiteRecord,
            onUpdateRecord: _updateBiteRecord,
            onDeleteRecord: _deleteBiteRecord,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // НОВЫЙ МЕТОД: Построение карточки ИИ-анализа
  Widget _buildAIAnalysisCard() {
    final localizations = AppLocalizations.of(context);

    if (_aiPrediction == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('ai_bite_forecast')),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        _aiPrediction!.overallScore,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: _getScoreColor(_aiPrediction!.overallScore),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.translate('ai_bite_forecast')} (${_aiPrediction!.overallScore}/100)',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getActivityLevelText(
                            _aiPrediction!.activityLevel,
                            localizations,
                          ),
                          style: TextStyle(
                            color: _getScoreColor(_aiPrediction!.overallScore),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        _aiPrediction!.overallScore,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_aiPrediction!.confidencePercent}%',
                      style: TextStyle(
                        color: _getScoreColor(_aiPrediction!.overallScore),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _aiPrediction!.recommendation,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (_aiPrediction!.tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  localizations.translate('recommendations'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...(_aiPrediction!.tips
                    .take(3)
                    .map(
                      (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: AppConstants.textColor.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Секция маркерных карт
  Widget _buildMarkerMapsSection() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('marker_maps')),

        if (_isLoadingMarkerMaps)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.textColor,
                ),
              ),
            ),
          )
        else
          Column(
            children:
            _linkedMarkerMaps
                .map((map) => _buildMarkerMapCard(map))
                .toList(),
          ),
      ],
    );
  }

  // Карточка для маркерной карты
  Widget _buildMarkerMapCard(MarkerMapModel map) {
    final localizations = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewMarkerMap(map),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Иконка маркерной карты
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.map,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Название и дата
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          map.name,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd.MM.yyyy').format(map.date),
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Количество маркеров
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${map.markers.length} ${_getMarkerText(map.markers.length)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Сектор (если есть)
              if (map.sector != null && map.sector!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.grid_on,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${localizations.translate('sector')}: ${map.sector}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Метод для правильного склонения слова "маркер"
  String _getMarkerText(int count) {
    final localizations = AppLocalizations.of(context);

    if (localizations.locale.languageCode == 'en') {
      return count == 1
          ? localizations.translate('marker')
          : localizations.translate('markers');
    }

    // Русская логика склонений
    if (count % 10 == 1 && count % 100 != 11) {
      return localizations.translate('marker');
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return localizations.translate('markers_2_4');
    } else {
      return localizations.translate('markers');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required int caughtFishCount,
    required int missedBitesCount,
  }) {
    final localizations = AppLocalizations.of(context);

    // Получение самой крупной рыбы
    final biggestFish = _note!.biggestFish;

    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип рыбалки
            Row(
              children: [
                Icon(Icons.category, color: AppConstants.textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('fishing_type')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.translate(
                      _note!.fishingType,
                    ), // ИСПРАВЛЕНО: добавлен перевод
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Место
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('location')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Даты
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('dates')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.isMultiDay && _note!.endDate != null
                        ? DateFormatter.formatDateRange(
                      _note!.date,
                      _note!.endDate!,
                      context,
                    )
                        : DateFormatter.formatDate(_note!.date, context),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Пойманные рыбы
            Row(
              children: [
                Icon(Icons.set_meal, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('caught')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$caughtFishCount ${DateFormatter.getFishText(caughtFishCount, context)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Нереализованные поклевки
            Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('not_realized')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$missedBitesCount ${_getBiteText(missedBitesCount)}',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Общий вес улова
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.scale, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${localizations.translate('total_catch_weight')}:',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_note!.totalFishWeight.toStringAsFixed(1)} ${localizations.translate('kg')}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Самая крупная рыба, если есть
            if (biggestFish != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('biggest_fish'),
                    style: TextStyle(
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (biggestFish.fishType.isNotEmpty)
                      Text(
                        biggestFish.fishType,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('weight')}: ${biggestFish.weight} ${localizations.translate('kg')}',
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 15,
                          ),
                        ),
                        if (biggestFish.length > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${localizations.translate('length')}: ${biggestFish.length} см',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${localizations.translate('bite_time')}: ${DateFormat('dd.MM.yyyy HH:mm').format(biggestFish.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ЗАМЕНЕНО: Вместо одной кнопки теперь две кнопки
            if (_note!.latitude != 0 && _note!.longitude != 0) ...[
              const SizedBox(height: 16),

              // Первая кнопка - Показать на карте
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLocationOnMap,
                  icon: Icon(
                    Icons.map,
                    color: AppConstants.textColor,
                    size: 20,
                  ),
                  label: Text(
                    localizations.translate('show_on_map'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Вторая кнопка - Построить маршрут
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToLocation,
                  icon: Icon(
                    Icons.navigation,
                    color: AppConstants.textColor,
                    size: 20,
                  ),
                  label: Text(
                    localizations.translate('build_route'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Метод для правильного склонения слова "поклевка"
  String _getBiteText(int count) {
    final localizations = AppLocalizations.of(context);

    if (localizations.locale.languageCode == 'en') {
      return count == 1 ? 'bite' : 'bites';
    }

    // Русская логика склонений
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поклевка';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'поклевки';
    } else {
      return 'поклевок';
    }
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Построение карточки погоды в современном стиле
  Widget _buildWeatherCard() {
    final localizations = AppLocalizations.of(context);
    final weather = _note!.weather;
    if (weather == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(localizations.translate('weather')),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ВЕРХНЯЯ ЧАСТЬ: температура и ощущается как
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      weather.isDay ? Icons.wb_sunny : Icons.nightlight_round,
                      color: weather.isDay ? Colors.amber : Colors.indigo[300],
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTemperature(weather.temperature),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.translate('feels_like_short')}: ${_formatTemperature(weather.feelsLike)}',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // НИЖНЯЯ ЧАСТЬ: сетка 2x3 с остальными данными
              _buildWeatherGrid(localizations, weather),
            ],
          ),
        ),
      ],
    );
  }

  // Новый метод для построения сетки погоды 2x3
  Widget _buildWeatherGrid(
      AppLocalizations localizations,
      FishingWeather weather,
      ) {
    return Column(
      children: [
        // Первая строка
        Row(
          children: [
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.air,
                label: localizations.translate('wind_short'),
                value:
                '${weather.windDirection}\n${_formatWindSpeed(weather.windSpeed)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.water_drop,
                label: localizations.translate('humidity_short'),
                value: '${weather.humidity}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.speed,
                label: localizations.translate('pressure_short'),
                value: _formatPressure(weather.pressure),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Вторая строка
        Row(
          children: [
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.cloud,
                label: localizations.translate('cloudiness_short'),
                value: '${weather.cloudCover}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.wb_twilight,
                label: localizations.translate('sunrise'),
                value: weather.sunrise,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWeatherInfoItem(
                icon: Icons.nights_stay,
                label: localizations.translate('sunset'),
                value: weather.sunset,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: TextStyle(color: AppConstants.textColor, fontSize: 16),
        ),
      ),
    );
  }
}