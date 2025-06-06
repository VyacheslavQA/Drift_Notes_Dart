// Путь: lib/screens/tournaments/tournament_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../models/tournament_model.dart';
import '../../localization/app_localizations.dart';
import '../../services/calendar_event_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentDetailScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  bool _isInCalendar = false;
  bool _isCheckingCalendar = true;
  bool _isUpdatingCalendar = false;

  @override
  void initState() {
    super.initState();
    _checkIfInCalendar();
  }

  Future<void> _checkIfInCalendar() async {
    try {
      final calendarService = CalendarEventService();
      final isInCalendar = await calendarService.isTournamentInCalendar(widget.tournament.id);

      if (mounted) {
        setState(() {
          _isInCalendar = isInCalendar;
          _isCheckingCalendar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingCalendar = false;
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
        title: Text(
          localizations.translate('tournament_details'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
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
          IconButton(
            icon: Icon(Icons.copy, color: AppConstants.textColor),
            onPressed: () => _copyTournamentInfo(context, localizations),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            _buildMainInfoCard(localizations),

            const SizedBox(height: 16),

            // Даты и время
            _buildDateTimeCard(localizations),

            const SizedBox(height: 16),

            // Место проведения
            _buildLocationCard(localizations),

            const SizedBox(height: 16),

            // Организатор
            _buildOrganizerCard(localizations),

            const SizedBox(height: 16),

            // Тип рыбалки
            _buildFishingTypeCard(localizations),

            const SizedBox(height: 16),

            // Дополнительная информация
            _buildAdditionalInfoCard(localizations),

            const SizedBox(height: 24),

            // Кнопки действий
            _buildActionButtons(context, localizations),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.surfaceColor,
            AppConstants.surfaceColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка турнира
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    widget.tournament.fishingType.iconPath,
                    width: 32,
                    height: 32,
                    color: AppConstants.textColor,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback к эмодзи если иконка не найдена
                      return Text(
                        widget.tournament.fishingType.icon,
                        style: const TextStyle(fontSize: 32),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Название и тип
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tournament.name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            localizations.translate(widget.tournament.fishingType.localizationKey),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.tournament.category.icon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                localizations.translate(widget.tournament.category.localizationKey),
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Статус
          if (widget.tournament.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('tournament_active'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (widget.tournament.isFuture)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('upcoming'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('completed'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('event_dates'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('date'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tournament.formattedDate,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('duration'),
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.tournament.duration} ${localizations.translate('hours')}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('venue'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            widget.tournament.location,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                localizations.translate('organizer'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            widget.tournament.organizer,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingTypeCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                widget.tournament.fishingType.iconPath,
                width: 24,
                height: 24,
                color: AppConstants.textColor,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback к эмодзи если иконка не найдена
                  return Text(
                    widget.tournament.fishingType.icon,
                    style: const TextStyle(fontSize: 24),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('fishing_type'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              localizations.translate(widget.tournament.fishingType.localizationKey),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded( // Добавлено Expanded для корректного отображения длинного текста
                child: Text(
                  localizations.translate('additional_info'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2, // Разрешаем до 2 строк
                  overflow: TextOverflow.ellipsis, // Добавляем многоточие при переполнении
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                    localizations.translate('month'),
                    widget.tournament.month
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                    localizations.translate('category'),
                    localizations.translate(widget.tournament.category.localizationKey)
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildInfoItem(
              localizations.translate('status'),
              _getTournamentStatus(localizations)
          ),
        ],
      ),
    );
  }

  String _getTournamentStatus(AppLocalizations localizations) {
    if (widget.tournament.isActive) return localizations.translate('active');
    if (widget.tournament.isFuture) return localizations.translate('future');
    return localizations.translate('finished');
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations localizations) {
    return Column(
      children: [
        // Кнопка создания заметки
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createFishingNote(context),
            icon: const Icon(Icons.note_add),
            label: Text(localizations.translate('create_fishing_note')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Кнопка добавления/удаления из календаря
        SizedBox(
          width: double.infinity,
          child: _buildCalendarButton(context, localizations),
        ),
      ],
    );
  }

  Widget _buildCalendarButton(BuildContext context, AppLocalizations localizations) {
    if (_isCheckingCalendar) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor.withValues(alpha: 0.5)),
          ),
        ),
        label: Text(localizations.translate('loading')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textColor.withValues(alpha: 0.5),
          side: BorderSide(color: AppConstants.textColor.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (_isInCalendar) {
      return OutlinedButton.icon(
        onPressed: _isUpdatingCalendar ? null : () => _removeFromCalendar(context, localizations),
        icon: _isUpdatingCalendar
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        )
            : const Icon(Icons.event_busy),
        label: Text(localizations.translate('remove_from_calendar')),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: _isUpdatingCalendar ? null : () => _addToCalendar(context, localizations),
        icon: _isUpdatingCalendar
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
          ),
        )
            : const Icon(Icons.calendar_today),
        label: Text(localizations.translate('add_to_calendar')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textColor,
          side: BorderSide(color: AppConstants.textColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _copyTournamentInfo(BuildContext context, AppLocalizations localizations) {
    final text = '''
${widget.tournament.category.icon} ${widget.tournament.name}

📅 ${localizations.translate('date')}: ${widget.tournament.formattedDate}
⏰ ${localizations.translate('duration')}: ${widget.tournament.duration} ${localizations.translate('hours')}
🎣 ${localizations.translate('fishing_type')}: ${localizations.translate(widget.tournament.fishingType.localizationKey)}
📍 ${localizations.translate('venue')}: ${widget.tournament.location}
👥 ${localizations.translate('organizer')}: ${widget.tournament.organizer}

#${widget.tournament.fishingType.displayName.toLowerCase().replaceAll(' ', '')} #турнир #рыбалка
    '''.trim();

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('tournament_info_copied')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createFishingNote(BuildContext context) {
    // Переход к созданию заметки с предзаполненными данными
    Navigator.pushNamed(
      context,
      '/fishing_type_selection',
      arguments: {
        'tournament': widget.tournament,
        'prefilledData': {
          'location': widget.tournament.location,
          'date': widget.tournament.startDate,
          'endDate': widget.tournament.endDate,
          'fishingType': widget.tournament.fishingType.displayName,
        },
      },
    );
  }

  void _addToCalendar(BuildContext context, AppLocalizations localizations) async {
    setState(() {
      _isUpdatingCalendar = true;
    });

    try {
      final calendarService = CalendarEventService();

      // Добавляем турнир в календарь с напоминанием за день
      await calendarService.addTournamentToCalendar(
        tournament: widget.tournament,
        reminderType: ReminderType.oneDay,
      );

      setState(() {
        _isInCalendar = true;
        _isUpdatingCalendar = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('tournament_added_to_calendar')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingCalendar = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_loading')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFromCalendar(BuildContext context, AppLocalizations localizations) async {
    setState(() {
      _isUpdatingCalendar = true;
    });

    try {
      final calendarService = CalendarEventService();
      final eventId = 'tournament_${widget.tournament.id}';

      // Удаляем турнир из календаря
      await calendarService.removeEvent(eventId);

      setState(() {
        _isInCalendar = false;
        _isUpdatingCalendar = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('tournament_removed_from_calendar')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingCalendar = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.translate('error_loading')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}