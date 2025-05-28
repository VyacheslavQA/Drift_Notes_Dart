// Путь: lib/screens/tournaments/tournament_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../models/tournament_model.dart';
import '../../localization/app_localizations.dart';
import '../../services/calendar_event_service.dart';

class TournamentDetailScreen extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentDetailScreen({
    super.key,
    required this.tournament,
  });

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
                  child: Text(
                    tournament.fishingType.icon,
                    style: const TextStyle(fontSize: 32),
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
                      tournament.name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tournament.fishingType.getDisplayName(localizations.translate),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tournament.category.icon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tournament.category.getDisplayName(localizations.translate),
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
          if (tournament.isActive)
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
          else if (tournament.isFuture)
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
                      tournament.formattedDate,
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
                      '${tournament.duration} ${localizations.translate('hours')}',
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
            tournament.location,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
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
            tournament.organizer,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
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
              Text(
                tournament.fishingType.icon,
                style: const TextStyle(fontSize: 24),
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
              tournament.fishingType.getDisplayName(localizations.translate),
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
              Text(
                localizations.translate('additional_info'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(localizations.translate('month'), tournament.month, localizations),
              ),
              Expanded(
                child: _buildInfoItem('ID', tournament.id, localizations),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(localizations.translate('category'), tournament.category.getDisplayName(localizations.translate), localizations),
              ),
              Expanded(
                child: _buildInfoItem(localizations.translate('status'), _getTournamentStatus(localizations), localizations),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTournamentStatus(AppLocalizations localizations) {
    if (tournament.isActive) return localizations.translate('active');
    if (tournament.isFuture) return localizations.translate('future');
    return localizations.translate('finished');
  }

  Widget _buildInfoItem(String label, String value, AppLocalizations localizations) {
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

        // Кнопка добавления в календарь
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addToCalendar(context, localizations),
            icon: const Icon(Icons.calendar_today),
            label: Text(localizations.translate('add_to_calendar')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.textColor,
              side: BorderSide(color: AppConstants.textColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _copyTournamentInfo(BuildContext context, AppLocalizations localizations) {
    final text = '''
${tournament.category.icon} ${tournament.name}

📅 ${localizations.translate('date')}: ${tournament.formattedDate}
⏰ ${localizations.translate('duration')}: ${tournament.duration} ${localizations.translate('hours')}
🎣 ${localizations.translate('fishing_type')}: ${tournament.fishingType.getDisplayName(localizations.translate)}
📍 ${localizations.translate('venue')}: ${tournament.location}
👥 ${localizations.translate('organizer')}: ${tournament.organizer}

#${tournament.fishingType.getDisplayName(localizations.translate).toLowerCase().replaceAll(' ', '')} #турнир #рыбалка
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
        'tournament': tournament,
        'prefilledData': {
          'location': tournament.location,
          'date': tournament.startDate,
          'endDate': tournament.endDate,
          'fishingType': tournament.fishingType.getDisplayName(AppLocalizations.of(context).translate),
        },
      },
    );
  }

  void _addToCalendar(BuildContext context, AppLocalizations localizations) {
    _showAddToCalendarDialog(context, localizations);
  }

  void _showAddToCalendarDialog(BuildContext context, AppLocalizations localizations) {
    ReminderType selectedReminder = ReminderType.oneDay;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.surfaceColor,
              title: Text(
                localizations.translate('add_to_calendar'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Добавить турнир "${tournament.name}" в календарь рыбалок?',
                    style: TextStyle(
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Напоминание:',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ReminderType.values.map((type) {
                    return RadioListTile<ReminderType>(
                      title: Text(
                        _getReminderTypeText(type, localizations),
                        style: TextStyle(color: AppConstants.textColor),
                      ),
                      value: type,
                      groupValue: selectedReminder,
                      activeColor: AppConstants.primaryColor,
                      onChanged: (ReminderType? value) {
                        setState(() {
                          selectedReminder = value!;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.translate('cancel'),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _performAddToCalendar(context, localizations, selectedReminder);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: Text(localizations.translate('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getReminderTypeText(ReminderType type, AppLocalizations localizations) {
    switch (type) {
      case ReminderType.none:
        return 'Без напоминания';
      case ReminderType.oneHour:
        return 'За 1 час';
      case ReminderType.oneDay:
        return 'За 1 день';
      case ReminderType.oneWeek:
        return 'За неделю';
    }
  }

  Future<void> _performAddToCalendar(BuildContext context, AppLocalizations localizations, ReminderType reminderType) async {
    try {
      final calendarService = CalendarEventService();

      await calendarService.addTournamentToCalendar(
        tournament: tournament,
        reminderType: reminderType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('tournament_added_to_calendar')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при добавлении в календарь: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}