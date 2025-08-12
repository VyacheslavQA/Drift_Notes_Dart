// Путь: lib/screens/fishing_diary/fishing_diary_import_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_diary_model.dart';
import '../../services/fishing_diary_share/fishing_diary_sharing_service.dart';
import '../../repositories/fishing_diary_repository.dart';
import '../../providers/subscription_provider.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/loading_overlay.dart';
import '../subscription/paywall_screen.dart';
import '../../constants/subscription_constants.dart';
import 'fishing_diary_list_screen.dart';

class FishingDiaryImportPreviewScreen extends StatefulWidget {
  final DiaryImportResult importResult;
  final String sourceFilePath;

  const FishingDiaryImportPreviewScreen({
    super.key,
    required this.importResult,
    required this.sourceFilePath,
  });

  @override
  State<FishingDiaryImportPreviewScreen> createState() => _FishingDiaryImportPreviewScreenState();
}

class _FishingDiaryImportPreviewScreenState extends State<FishingDiaryImportPreviewScreen> {
  final _fishingDiaryRepository = FishingDiaryRepository();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _nameConflict = false;
  List<FishingDiaryModel> _existingEntries = [];

  @override
  void initState() {
    super.initState();
    // 🔧 ИСПРАВЛЕНО: используем title вместо waterBodyName
    _nameController.text = widget.importResult.diaryEntry?.title ?? '';
    _loadExistingEntries();
    _checkPremiumAccess();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 🔒 Проверка Premium доступа при инициализации
  void _checkPremiumAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      if (!subscriptionProvider.hasPremiumAccess) {
        debugPrint('🚫 Доступ к импорту записей заблокирован - показываем PaywallScreen');

        // Показываем PaywallScreen для импорта записей
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(
              contentType: 'fishing_diary_sharing',
              blockedFeature: 'Импорт записей дневника',
            ),
          ),
        );
      }
    });
  }

  /// Загрузка существующих записей для проверки конфликтов имен
  Future<void> _loadExistingEntries() async {
    try {
      setState(() => _isLoading = true);

      // 🔧 ИСПРАВЛЕНО: используем правильное название метода
      _existingEntries = await _fishingDiaryRepository.getUserFishingDiaryEntries();
      _checkNameConflict();

    } catch (e) {
      debugPrint('❌ Ошибка загрузки существующих записей: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Проверка конфликта имен
  void _checkNameConflict() {
    final currentName = _nameController.text.trim();
    // 🔧 ИСПРАВЛЕНО: используем title вместо waterBodyName
    final hasConflict = _existingEntries.any((entry) =>
    entry.title.toLowerCase() == currentName.toLowerCase());

    setState(() {
      _nameConflict = hasConflict;
    });
  }

  /// 🚀 Импорт записи с правильной навигацией
  Future<void> _importEntry() async {
    final localizations = AppLocalizations.of(context);

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // 🔧 ИСПРАВЛЕНО: изменили сообщение
          content: Text(localizations.translate('enter_entry_title')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Финальная проверка Premium доступа
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.hasPremiumAccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            contentType: 'fishing_diary_sharing',
            blockedFeature: 'Импорт записей дневника',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔧 ИСПРАВЛЕНО: используем title вместо waterBodyName
      final updatedEntry = widget.importResult.diaryEntry!.copyWith(
        title: _nameController.text.trim(),
      );

      // Импортируем через сервис
      final success = await FishingDiarySharingService.importDiaryEntry(
        diaryEntry: updatedEntry,
        onImport: (entry) async {
          // 🔧 ИСПРАВЛЕНО: используем правильное название метода
          await _fishingDiaryRepository.addFishingDiaryEntry(entry);
        },
      );

      if (success && mounted) {
        // Обновляем данные подписки
        try {
          await subscriptionProvider.refreshUsageData();
        } catch (e) {
          debugPrint('⚠️ Не удалось обновить данные подписки: $e');
        }

        debugPrint('✅ Запись успешно импортирована, переходим к списку записей');

        // Принудительный переход к списку записей
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const FishingDiaryListScreen(),
          ),
              (route) => false, // Очищаем весь стек навигации
        );

        // Показываем сообщение об успешном импорте
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.translate('entry_imported_successfully')),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });

      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('import_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка импорта: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('import_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final importResult = widget.importResult;

    if (!importResult.isSuccess || importResult.diaryEntry == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: Text(
            localizations.translate('import_error'),
            style: TextStyle(color: AppConstants.textColor),
          ),
          backgroundColor: AppConstants.backgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  importResult.error ?? localizations.translate('unknown_error'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: Text(
                    localizations.translate('close'),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final diaryEntry = importResult.diaryEntry!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('import_diary_entry'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: localizations.translate('importing_entry'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📋 Карточка с информацией о файле
              _buildFileInfoCard(),

              const SizedBox(height: 16),

              // ✏️ Поле редактирования названия
              _buildNameEditField(),

              const SizedBox(height: 20),

              // 📊 Статистика записи
              _buildEntryStatistics(),

              const SizedBox(height: 20),

              // 📝 Описание записи (если есть)
              if (diaryEntry.description.isNotEmpty)
                _buildDescriptionCard(),

              const SizedBox(height: 100), // Отступ для кнопки
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nameController.text.trim().isNotEmpty ? _importEntry : null,
        backgroundColor: _nameController.text.trim().isNotEmpty
            ? AppConstants.primaryColor
            : Colors.grey,
        foregroundColor: AppConstants.textColor,
        icon: const Icon(Icons.download),
        label: Text(
          localizations.translate('import_entry'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 📋 Карточка с информацией о файле
  Widget _buildFileInfoCard() {
    final localizations = AppLocalizations.of(context);
    final importResult = widget.importResult;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.file_download,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('received_diary_entry'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (importResult.originalFileName != null)
                        Text(
                          importResult.originalFileName!,
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (importResult.exportDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppConstants.textColor.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${localizations.translate('exported')}: ${DateFormat('dd.MM.yyyy HH:mm').format(importResult.exportDate!)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✏️ Поле редактирования названия
  Widget _buildNameEditField() {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔧 ИСПРАВЛЕНО: изменили label
        Text(
          localizations.translate('entry_title'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(color: AppConstants.textColor),
          decoration: InputDecoration(
            // 🔧 ИСПРАВЛЕНО: изменили hint
            hintText: localizations.translate('enter_entry_title'),
            hintStyle: TextStyle(
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppConstants.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _nameConflict ? Colors.orange : AppConstants.primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (_) => _checkNameConflict(),
        ),
        if (_nameConflict) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  localizations.translate('entry_name_exists'),
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 📊 Статистика записи
  Widget _buildEntryStatistics() {
    final localizations = AppLocalizations.of(context);
    final diaryEntry = widget.importResult.diaryEntry!;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('entry_information'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 🔧 ИСПРАВЛЕНО: используем реальные поля модели
            _buildStatItem(
              icon: Icons.calendar_today,
              label: localizations.translate('created'),
              value: DateFormat('dd.MM.yyyy').format(diaryEntry.createdAt),
            ),

            _buildStatItem(
              icon: Icons.update,
              label: localizations.translate('updated'),
              value: DateFormat('dd.MM.yyyy').format(diaryEntry.updatedAt),
            ),

            if (diaryEntry.isFavorite)
              _buildStatItem(
                icon: Icons.star,
                label: localizations.translate('favorite'),
                value: localizations.translate('yes'),
              ),
          ],
        ),
      ),
    );
  }

  /// 📊 Элемент статистики
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppConstants.textColor.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Карточка описания
  Widget _buildDescriptionCard() {
    final localizations = AppLocalizations.of(context);
    final description = widget.importResult.diaryEntry!.description;

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('description'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}