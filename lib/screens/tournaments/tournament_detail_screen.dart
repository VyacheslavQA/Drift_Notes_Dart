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
  final CalendarEventService _calendarService = CalendarEventService();
  bool _isAddingToCalendar = false;

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
            fontSize: 20, // Уменьшил размер
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
            onPressed: () => _copyTournamentInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            _buildMainInfoCard(),

            const SizedBox(height: 16),

            // Даты и время
            _buildDateTimeCard(),

            const SizedBox(height: 16),

            // Место проведения
            _buildLocationCard(),

            const SizedBox(height: 16),

            // Организатор
            _buildOrganizerCard(),

            const SizedBox(height: 16),

            // Дополнительная информация
            _buildAdditionalInfoCard(),

            const SizedBox(height: 24),

            // Кнопка действия
            _buildActionButton(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
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
                width: 50, // Уменьшил размер
                height: 50,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.tournament.type.icon,
                    style: const TextStyle(fontSize: 28), // Уменьшил размер
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
                        fontSize: 18, // Уменьшил размер
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // Добавил ограничение строк
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                        widget.tournament.type.displayName,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 11, // Уменьшил размер
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  const Icon(Icons.play_arrow, color: Colors.white, size: 16), // Уменьшил иконку
                  const SizedBox(width: 8),
                  Text(
                    'ТУРНИР АКТИВЕН',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 12, // Уменьшил размер
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
                  const Icon(Icons.schedule, color: Colors.white, size: 16), // Уменьшил иконку
                  const SizedBox(width: 8),
                  Text(
                    'ПРЕДСТОЯЩИЙ',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 12, // Уменьшил размер
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
                  const Icon(Icons.check_circle, color: Colors.white, size: 16), // Уменьшил иконку
                  const SizedBox(width: 8),
                  Text(
                    'ЗАВЕРШЕН',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 12, // Уменьшил размер
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

  Widget _buildDateTimeCard() {
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
              Icon(Icons.event, color: AppConstants.primaryColor, size: 20), // Уменьшил иконку
              const SizedBox(width: 12),
              Text(
                'Даты проведения',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16, // Уменьшил размер
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
                      'Дата',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 12, // Уменьшил размер
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tournament.formattedDate,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14, // Уменьшил размер
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
                      'Продолжительность',
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.7),
                        fontSize: 12, // Уменьшил размер
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.tournament.duration} часов',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 14, // Уменьшил размер
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

  Widget _buildLocationCard() {
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
              Icon(Icons.location_on, color: AppConstants.primaryColor, size: 20), // Уменьшил иконку
              const SizedBox(width: 12),
              Text(
                'Место проведения',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16, // Уменьшил размер
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
              fontSize: 14, // Уменьшил размер
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Сектор: ',
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontSize: 12, // Уменьшил размер
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.tournament.sector,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 12, // Уменьшил размер
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard() {
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
              Icon(Icons.group, color: AppConstants.primaryColor, size: 20), // Уменьшил иконку
              const SizedBox(width: 12),
              Text(
                'Организатор',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16, // Уменьшил размер
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
              fontSize: 14, // Уменьшил размер
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
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
              Icon(Icons.info, color: AppConstants.primaryColor, size: 20), // Уменьшил иконку
              const SizedBox(width: 12),
              Text(
                'Дополнительная информация',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16, // Уменьшил размер
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Месяц', widget.tournament.month),
              ),
              Expanded(
                child: _buildInfoItem('Тип турнира', widget.tournament.type.displayName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 12, // Уменьшил размер
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14, // Уменьшил размер
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAddingToCalendar ? null : () => _addToCalendar(context),
        icon: _isAddingToCalendar
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.calendar_today),
        label: Text(_isAddingToCalendar ? 'Добавление...' : 'Добавить в календарь'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _copyTournamentInfo(BuildContext context) {
    final text = '''
🏆 ${widget.tournament.name}

📅 Дата: ${widget.tournament.formattedDate}
⏰ Продолжительность: ${widget.tournament.duration} часов
📍 Место: ${widget.tournament.location}
👥 Организатор: ${widget.tournament.organizer}
🎯 Сектор: ${widget.tournament.sector}

#турнир #рыбалка #соревнования
    '''.trim();

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Информация о турнире скопирована в буфер обмена'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addToCalendar(BuildContext context) async {
    setState(() {
      _isAddingToCalendar = true;
    });

    try {
      // Показываем диалог выбора напоминания
      final reminderType = await _showReminderDialog(context);

      if (reminderType != null) {
        // Добавляем событие в календарь
        await _calendarService.addTournamentToCalendar(
          tournament: widget.tournament,
          reminderType: reminderType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Турнир добавлен в календарь рыбалок'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении в календарь: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCalendar = false;
        });
      }
    }
  }

  Future<ReminderType?> _showReminderDialog(BuildContext context) async {
    return showDialog<ReminderType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text(
            'Когда напомнить?',
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReminderOption(context, 'За 1 час', ReminderType.oneHour),
              _buildReminderOption(context, 'За 1 день', ReminderType.oneDay),
              _buildReminderOption(context, 'За 1 неделю', ReminderType.oneWeek),
              _buildReminderOption(context, 'Без напоминания', ReminderType.none),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: TextStyle(color: AppConstants.textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderOption(BuildContext context, String title, ReminderType type) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: AppConstants.textColor),
      ),
      onTap: () => Navigator.pop(context, type),
    );
  }
}