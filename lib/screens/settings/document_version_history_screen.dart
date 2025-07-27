// Путь: lib/screens/settings/document_version_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../services/user_consent_service.dart';
import '../../models/user_consent_models.dart';
import '../help/privacy_policy_screen.dart';
import '../help/terms_of_service_screen.dart';

/// ✅ УПРОЩЕННАЯ версия экрана информации о документах
/// Показывает только текущие версии и статус принятия
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
  UserConsentStatus? _consentStatus;
  ConsentCheckResult? _consentResult;
  String _currentVersionString = '';
  bool _isDependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    // НЕ вызываем _loadVersionInfo() здесь!
    // Перенесено в didChangeDependencies()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Выполняем инициализацию только один раз после того, как dependencies готовы
    if (!_isDependenciesInitialized) {
      _isDependenciesInitialized = true;
      _loadVersionInfo();
    }
  }

  /// ✅ ИСПРАВЛЕНО: Загружаем только текущую версию и статус
  Future<void> _loadVersionInfo() async {
    if (!mounted) return;

    try {
      // Теперь безопасно использовать AppLocalizations.of(context)
      final localizations = AppLocalizations.of(context);
      final languageCode = localizations.locale.languageCode;

      // ✅ ИСПРАВЛЕНО: Используем существующие методы
      if (widget.documentType == 'privacy_policy') {
        _currentVersionString = await _consentService.getCurrentPrivacyPolicyVersion(languageCode);
      } else {
        _currentVersionString = await _consentService.getCurrentTermsOfServiceVersion(languageCode);
      }

      // Получаем статус согласий
      _consentStatus = await _consentService.getUserConsentStatus(languageCode);

      // Получаем результат проверки согласий для селективного статуса
      _consentResult = await _consentService.checkUserConsents(languageCode);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading version information: $e');
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
    return _currentVersionString.isNotEmpty ? _currentVersionString : '1.0.0';
  }

  /// Проверяет нужно ли обновление конкретного документа
  bool _needsUpdate() {
    if (_consentResult == null) return false;

    if (widget.documentType == 'privacy_policy') {
      return _consentResult!.needPrivacyPolicy;
    } else {
      return _consentResult!.needTermsOfService;
    }
  }

  /// Получает статус принятия конкретного документа
  bool _isDocumentAccepted() {
    if (_consentStatus == null) return false;

    if (widget.documentType == 'privacy_policy') {
      return _consentStatus!.privacyPolicyAccepted;
    } else {
      return _consentStatus!.termsOfServiceAccepted;
    }
  }

  /// Получает сохраненную версию документа
  String? _getSavedVersion() {
    if (_consentResult == null) return null;

    if (widget.documentType == 'privacy_policy') {
      return _consentResult!.savedPrivacyVersion;
    } else {
      return _consentResult!.savedTermsVersion;
    }
  }

  /// Открытие документа для чтения
  void _openDocumentForReading() {
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
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _getDocumentTitle(localizations),
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
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryColor,
        ),
      )
          : _buildContent(localizations),
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о текущей версии
          _buildCurrentVersionCard(localizations),

          const SizedBox(height: 24),

          // Информация о статусе
          _buildStatusCard(localizations),

          const SizedBox(height: 24),

          // Кнопка для чтения документа
          _buildReadDocumentButton(localizations),
        ],
      ),
    );
  }

  /// Карточка с информацией о текущей версии
  Widget _buildCurrentVersionCard(AppLocalizations localizations) {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAccepted && !needsUpdate
              ? AppConstants.primaryColor
              : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.translate('current_version') ?? 'Current version',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Версия
            _buildInfoRow(
              Icons.tag,
              localizations.translate('version') ?? 'Version',
              _getCurrentVersion(),
            ),

            const SizedBox(height: 12),

            // Дата последнего принятия
            if (_consentStatus?.consentTimestamp != null)
              _buildInfoRow(
                Icons.schedule,
                localizations.translate('accepted_date') ?? 'Accepted date',
                _formatDate(_consentStatus!.consentTimestamp!),
              ),

            const SizedBox(height: 16),

            // Статус принятия
            _buildStatusIndicator(localizations),
          ],
        ),
      ),
    );
  }

  /// Карточка со статусом
  Widget _buildStatusCard(AppLocalizations localizations) {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();
    final savedVersion = _getSavedVersion();

    return Card(
      color: AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.translate('status_information') ?? 'Status Information',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (savedVersion != null) ...[
              _buildInfoRow(
                Icons.history,
                localizations.translate('your_version') ?? 'Your version',
                savedVersion,
              ),
              const SizedBox(height: 12),
            ],

            // Описание статуса
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusTitle(localizations),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(localizations),
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка для чтения документа
  Widget _buildReadDocumentButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openDocumentForReading,
        icon: const Icon(
          Icons.visibility,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          localizations.translate('read_document') ?? 'Read Document',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Индикатор статуса
  Widget _buildStatusIndicator(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusTitle(localizations),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Строка с информацией
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppConstants.textColor.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
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
    );
  }

  /// Получает цвет статуса
  Color _getStatusColor() {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    if (!isAccepted) {
      return Colors.red;
    } else if (needsUpdate) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Получает иконку статуса
  IconData _getStatusIcon() {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    if (!isAccepted) {
      return Icons.close;
    } else if (needsUpdate) {
      return Icons.update;
    } else {
      return Icons.check;
    }
  }

  /// Получает заголовок статуса
  String _getStatusTitle(AppLocalizations localizations) {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    if (!isAccepted) {
      return localizations.translate('not_accepted') ?? 'Not Accepted';
    } else if (needsUpdate) {
      return localizations.translate('update_required') ?? 'Update Required';
    } else {
      return localizations.translate('accepted') ?? 'Accepted';
    }
  }

  /// Получает описание статуса
  String _getStatusDescription(AppLocalizations localizations) {
    final needsUpdate = _needsUpdate();
    final isAccepted = _isDocumentAccepted();

    if (!isAccepted) {
      return localizations.translate('document_not_accepted_desc') ??
          'You have not accepted this document yet. Please read and accept it to continue using the app.';
    } else if (needsUpdate) {
      return localizations.translate('document_update_required_desc') ??
          'This document has been updated. Please review the new version and accept the changes.';
    } else {
      return localizations.translate('document_accepted_desc') ??
          'You have accepted the current version of this document.';
    }
  }

  /// Форматирует дату
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}