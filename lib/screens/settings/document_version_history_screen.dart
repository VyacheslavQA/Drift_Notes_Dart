// Путь: lib/screens/settings/document_version_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/user_consent_service.dart';
import '../../models/user_consent_models.dart';
import '../help/privacy_policy_screen.dart';
import '../help/terms_of_service_screen.dart';

class DocumentVersionHistoryScreen extends StatefulWidget {
  final String documentType; // 'privacy_policy' или 'terms_of_service'

  const DocumentVersionHistoryScreen({super.key, required this.documentType});

  @override
  State<DocumentVersionHistoryScreen> createState() =>
      _DocumentVersionHistoryScreenState();
}

class _DocumentVersionHistoryScreenState
    extends State<DocumentVersionHistoryScreen> {
  final UserConsentService _consentService = UserConsentService();

  bool _isLoading = true;
  List<DocumentVersion> _versions = [];
  UserConsentStatus? _consentStatus;
  ConsentCheckResult? _consentResult; // НОВОЕ: Результат проверки согласий
  String _currentVersionString = '';
  bool _isDependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    // НЕ вызываем _loadVersionHistory() здесь!
    // Перенесено в didChangeDependencies()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Выполняем инициализацию только один раз после того, как dependencies готовы
    if (!_isDependenciesInitialized) {
      _isDependenciesInitialized = true;
      _loadVersionHistory();
    }
  }

  Future<void> _loadVersionHistory() async {
    if (!mounted) return;

    try {
      // Теперь безопасно использовать AppLocalizations.of(context)
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      if (widget.documentType == 'privacy_policy') {
        _versions = await _consentService.getPrivacyPolicyHistory(languageCode);
        _currentVersionString = await _consentService
            .getCurrentPrivacyPolicyVersion(languageCode);
      } else {
        _versions = await _consentService.getTermsOfServiceHistory(
          languageCode,
        );
        _currentVersionString = await _consentService
            .getCurrentTermsOfServiceVersion(languageCode);
      }

      _consentStatus = await _consentService.getUserConsentStatus(languageCode);

      // НОВОЕ: Получаем результат проверки согласий для селективного статуса
      _consentResult = await _consentService.checkUserConsents(languageCode);

      // Сортируем версии по дате выпуска (новые сверху)
      _versions.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки истории версий: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDocumentTitle(AppLocalizations localizations) {
    return widget.documentType == 'privacy_policy'
        ? (localizations.translate('privacy_policy') ?? 'Privacy Policy')
        : (localizations.translate('terms_of_service') ?? 'Terms of Service');
  }

  String _getCurrentVersion() {
    return _currentVersionString;
  }

  // НОВЫЙ МЕТОД: Проверяет нужно ли обновление конкретного документа
  bool _needsUpdate() {
    if (_consentResult == null) return false;

    if (widget.documentType == 'privacy_policy') {
      return _consentResult!.needPrivacyPolicy;
    } else {
      return _consentResult!.needTermsOfService;
    }
  }

  // НОВЫЙ МЕТОД: Получает статус принятия конкретного документа
  bool _isDocumentAccepted() {
    if (_consentStatus == null) return false;

    if (widget.documentType == 'privacy_policy') {
      return _consentStatus!.privacyPolicyAccepted;
    } else {
      return _consentStatus!.termsOfServiceAccepted;
    }
  }

  /// НОВЫЙ МЕТОД: Открытие документа для чтения
  void _openDocumentForReading(DocumentVersion version) {
    if (version.isCurrent) {
      // Если текущая версия - открываем обычные экраны
      if (widget.documentType == 'privacy_policy') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
        );
      }
    } else {
      // Если архивная версия - открываем специальный экран
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ArchivedDocumentViewerScreen(
                documentType: widget.documentType,
                version: version.version,
                documentTitle: _getDocumentTitle(AppLocalizations.of(context)),
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          '${localizations.translate('version_history') ?? 'Version History'}: ${_getDocumentTitle(localizations)}',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              )
              : _buildContent(localizations),
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    if (_versions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_version_history') ??
                  'No version history available',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Информация о текущей версии
        _buildCurrentVersionHeader(localizations),

        // Список версий
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _versions.length,
            itemBuilder: (context, index) {
              return _buildVersionCard(_versions[index], localizations, index);
            },
          ),
        ),
      ],
    );
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Показывает статус конкретного документа
  Widget _buildCurrentVersionHeader(AppLocalizations localizations) {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    return Container(
      width: double.infinity,
      color: AppConstants.primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('current_version') ?? 'Current version',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isAccepted && !needsUpdate ? Icons.check_circle : Icons.warning,
                color:
                    isAccepted && !needsUpdate
                        ? AppConstants.primaryColor
                        : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getCurrentVersion(),
                style: TextStyle(
                  color:
                      isAccepted && !needsUpdate
                          ? AppConstants.primaryColor
                          : Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // НОВАЯ ЛОГИКА: Показываем статус конкретного документа
          if (!isAccepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Не принято',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (needsUpdate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Требуется обновление',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Принято',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(
    DocumentVersion version,
    AppLocalizations localizations,
    int index,
  ) {
    final isCurrent = version.version == _getCurrentVersion();

    return Card(
      color: AppConstants.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isCurrent
                ? BorderSide(color: AppConstants.primaryColor, width: 2)
                : BorderSide.none,
      ),
      child: Column(
        children: [
          // Основная информация о версии
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок версии
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCurrent
                                ? AppConstants.primaryColor
                                : AppConstants.textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${localizations.translate('version') ?? 'Version'} ${version.version}',
                        style: TextStyle(
                          color:
                              isCurrent ? Colors.white : AppConstants.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Text(
                          localizations.translate('current') ?? 'Current',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (!isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Text(
                          localizations.translate('archived_version') ??
                              'Archived Version',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Информация о версии
                _buildVersionInfoRow(
                  Icons.calendar_today,
                  localizations.translate('release_date') ?? 'Release date',
                  _formatDate(version.releaseDate),
                ),

                if (version.description != null) ...[
                  const SizedBox(height: 8),
                  _buildVersionInfoRow(
                    Icons.description,
                    localizations.translate('description') ?? 'Description',
                    version.description!,
                  ),
                ],

                if (version.hash != null) ...[
                  const SizedBox(height: 8),
                  _buildVersionInfoRow(
                    Icons.fingerprint,
                    localizations.translate('hash') ?? 'Hash',
                    version.hash!,
                  ),
                ],

                // ИСПРАВЛЕНО: Показываем правильный язык документа
                _buildVersionInfoRow(
                  Icons.language,
                  localizations.translate('language') ?? 'Language',
                  _getLanguageDisplayName(version.language),
                ),
              ],
            ),
          ),

          // Кнопка "Прочитать" с локализацией
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDocumentForReading(version),
                icon: Icon(
                  isCurrent ? Icons.visibility : Icons.history_edu,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  localizations.translate('read') ?? 'Read',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCurrent ? AppConstants.primaryColor : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// НОВЫЙ МЕТОД: Получает читаемое название языка
  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ru':
        return 'RU';
      case 'en':
        return 'EN';
      default:
        return languageCode.toUpperCase();
    }
  }

  Widget _buildVersionInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppConstants.textColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Просмотр архивных версий документов с правильным языком
class ArchivedDocumentViewerScreen extends StatefulWidget {
  final String documentType;
  final String version;
  final String documentTitle;

  const ArchivedDocumentViewerScreen({
    super.key,
    required this.documentType,
    required this.version,
    required this.documentTitle,
  });

  @override
  State<ArchivedDocumentViewerScreen> createState() =>
      _ArchivedDocumentViewerScreenState();
}

class _ArchivedDocumentViewerScreenState
    extends State<ArchivedDocumentViewerScreen> {
  String _documentText = '';
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    // НЕ загружаем документ здесь!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Загружаем только один раз
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadArchivedDocument();
    }
  }

  Future<void> _loadArchivedDocument() async {
    if (!mounted) return;

    try {
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // Формируем путь к архивному файлу
      final fileName =
          'assets/${widget.documentType}/${widget.documentType}_${languageCode}_v${widget.version}.txt';

      debugPrint('🔍 Загружаем архивный документ: $fileName');

      String documentText;
      try {
        documentText = await rootBundle.loadString(fileName);
        debugPrint('✅ Успешно загружен архивный документ: $fileName');
      } catch (e) {
        debugPrint('❌ Не удалось загрузить $fileName: $e');
        // Если архивная версия не найдена, пробуем загрузить текущую
        try {
          final currentFileName =
              'assets/${widget.documentType}/${widget.documentType}_$languageCode.txt';
          documentText = await rootBundle.loadString(currentFileName);
          debugPrint('✅ Загружена текущая версия как замена: $currentFileName');
        } catch (e2) {
          debugPrint('❌ Не удалось загрузить и текущую версию: $e2');
          throw Exception(
            localizations.translate('document_loading_error') ??
                'Failed to load document',
          );
        }
      }

      if (mounted) {
        setState(() {
          _documentText = documentText;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Критическая ошибка при загрузке архивного документа: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        setState(() {
          _documentText =
              '${localizations.translate('document_loading_error') ?? 'Error loading archived document'}\n\n${localizations.translate('error') ?? 'Error'}: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentTitle,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${localizations.translate('version') ?? 'Version'} ${widget.version}',
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              )
              : Column(
                children: [
                  // ВОДЯНОЙ ЗНАК "Архивная версия" с локализацией
                  Container(
                    width: double.infinity,
                    color: Colors.orange.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.archive, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${localizations.translate('archived_version') ?? 'Archived version'} ${widget.version}',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Text(
                            localizations.translate('read_only') ?? 'Read only',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Содержимое документа
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppConstants.textColor.withValues(
                              alpha: 0.1,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _documentText,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
