// Путь: lib/screens/calendar/fishing_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import '../../localization/app_localizations.dart';
import '../fishing_note/fishing_note_detail_screen.dart';
import '../fishing_note/add_fishing_note_screen.dart';
import '../../services/calendar_event_service.dart';
import '../tournaments/tournament_detail_screen.dart';
import '../../services/tournament_service.dart';

class FishingCalendarScreen extends StatefulWidget {
  const FishingCalendarScreen({super.key});

  @override
  State<FishingCalendarScreen> createState() => _FishingCalendarScreenState();
}

class _FishingCalendarScreenState extends State<FishingCalendarScreen>
    with SingleTickerProviderStateMixin {
  final _fishingNoteRepository = FishingNoteRepository();
  final CalendarEventService _calendarEventService = CalendarEventService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final Map<DateTime, List<FishingNoteModel>> _fishingEvents = {};
  List<CalendarEvent> _calendarEvents = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Цвета для разных состояний
  final Color _pastFishingColor = const Color(0xFF2E7D32);
  final Color _futureFishingColor = const Color(0xFFFF8F00);
  final Color _tournamentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadFishingNotes();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: ResponsiveConstants.animationNormal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFishingNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await _fishingNoteRepository.getUserFishingNotes();
      final events = await _calendarEventService.getCalendarEvents();
      _calendarEvents = events;
      _processNotesForCalendar(notes);

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading')}: $e',
            ),
          ),
        );
      }
    }
  }

  void _processNotesForCalendar(List<FishingNoteModel> notes) {
    _fishingEvents.clear();

    for (var note in notes) {
      if (!note.isMultiDay) {
        final dateKey = DateTime(note.date.year, note.date.month, note.date.day);
        _fishingEvents[dateKey] = _fishingEvents[dateKey] ?? [];
        _fishingEvents[dateKey]!.add(note);
      } else {
        DateTime startDate = DateTime(note.date.year, note.date.month, note.date.day);
        DateTime endDate = note.endDate != null
            ? DateTime(note.endDate!.year, note.endDate!.month, note.endDate!.day)
            : startDate;

        int totalDays = endDate.difference(startDate).inDays + 1;

        for (int i = 0; i < totalDays; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);

          _fishingEvents[dateKey] = _fishingEvents[dateKey] ?? [];
          _fishingEvents[dateKey]!.add(note);
        }
      }
    }
  }

  List<FishingNoteModel> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _fishingEvents[dateKey] ?? [];
  }

  List<CalendarEvent> _getCalendarEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _calendarEvents.where((event) {
      final eventStartDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      final eventEndDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);

      return dateKey.isAtSameMomentAs(eventStartDate) ||
          dateKey.isAtSameMomentAs(eventEndDate) ||
          (dateKey.isAfter(eventStartDate) && dateKey.isBefore(eventEndDate));
    }).toList();
  }

  bool _isPastFishing(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _planNewFishing() async {
    final selectedDate = _selectedDay ?? DateTime.now();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFishingNoteScreen(
          fishingType: AppConstants.fishingTypes.first,
          initialDate: selectedDate,
        ),
      ),
    );

    if (result == true) {
      _loadFishingNotes();
    }
  }

  void _planNewFishingForDate(DateTime date) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFishingNoteScreen(
          fishingType: AppConstants.fishingTypes.first,
          initialDate: date,
        ),
      ),
    );

    if (result == true) {
      _loadFishingNotes();
    }
  }

  void _viewNoteDetails(FishingNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FishingNoteDetailScreen(noteId: note.id),
      ),
    ).then((value) {
      if (value == true) {
        _loadFishingNotes();
      }
    });
  }

  void _viewTournamentDetails(CalendarEvent event) async {
    try {
      final tournamentService = TournamentService();
      final tournament = tournamentService.getTournamentById(event.sourceId ?? event.id);

      if (tournament != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailScreen(tournament: tournament),
          ),
        );

        if (result == true) {
          _loadFishingNotes();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('tournament_not_found'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_loading')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMonthYearPicker() async {
    final localizations = AppLocalizations.of(context);
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = _focusedDay.year;
        int selectedMonth = _focusedDay.month;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.cardColor,
              title: Text(
                localizations.translate('select_date_to_view'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: double.infinity,
                    tablet: 300,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Выбор года
                    Container(
                      constraints: BoxConstraints(
                        minHeight: ResponsiveConstants.minTouchTarget,
                      ),
                      child: DropdownButton<int>(
                        value: selectedYear,
                        dropdownColor: AppConstants.cardColor,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        ),
                        items: List.generate(11, (index) => 2020 + index)
                            .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(height: ResponsiveConstants.spacingM),
                    // Выбор месяца
                    Container(
                      constraints: BoxConstraints(
                        minHeight: ResponsiveConstants.minTouchTarget,
                      ),
                      child: DropdownButton<int>(
                        value: selectedMonth,
                        dropdownColor: AppConstants.cardColor,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                        ),
                        items: List.generate(12, (index) => index + 1)
                            .map((month) => DropdownMenuItem(
                          value: month,
                          child: Text(
                            localizations.translate(_getMonthKey(month)),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size(
                      ResponsiveConstants.minTouchTarget,
                      ResponsiveConstants.minTouchTarget,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.translate('cancel'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    minimumSize: Size(
                      ResponsiveConstants.minTouchTarget,
                      ResponsiveConstants.minTouchTarget,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  child: Text(
                    localizations.translate('continue'),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _focusedDay = selectedDate;
      });
    }
  }

  String _getMonthKey(int month) {
    const monthKeys = [
      '', 'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
    ];
    return monthKeys[month];
  }

  String _getTitleText() {
    final localizations = AppLocalizations.of(context);
    final monthKey = _getMonthKey(_focusedDay.month);
    final monthName = localizations.translate(monthKey);
    final year = _focusedDay.year.toString();

    // Только первые 3 символа месяца + только последние 2 цифры года
    final shortMonth = monthName.substring(0, math.min(3, monthName.length));
    final shortYear = year.substring(2); // 2025 -> 25

    return '$shortMonth $shortYear';
  }

  String _getDayOfWeekText(int weekday, {bool short = false}) {
    final localizations = AppLocalizations.of(context);
    final isEnglish = localizations.locale.languageCode == 'en';

    if (short) {
      if (isEnglish) {
        switch (weekday) {
          case DateTime.monday: return 'Mo';
          case DateTime.tuesday: return 'Tu';
          case DateTime.wednesday: return 'We';
          case DateTime.thursday: return 'Th';
          case DateTime.friday: return 'Fr';
          case DateTime.saturday: return 'Sa';
          case DateTime.sunday: return 'Su';
          default: return '';
        }
      } else {
        switch (weekday) {
          case DateTime.monday: return 'Пн';
          case DateTime.tuesday: return 'Вт';
          case DateTime.wednesday: return 'Ср';
          case DateTime.thursday: return 'Чт';
          case DateTime.friday: return 'Пт';
          case DateTime.saturday: return 'Сб';
          case DateTime.sunday: return 'Вс';
          default: return '';
        }
      }
    } else {
      if (isEnglish) {
        switch (weekday) {
          case DateTime.monday: return 'Mon';
          case DateTime.tuesday: return 'Tue';
          case DateTime.wednesday: return 'Wed';
          case DateTime.thursday: return 'Thu';
          case DateTime.friday: return 'Fri';
          case DateTime.saturday: return 'Sat';
          case DateTime.sunday: return 'Sun';
          default: return '';
        }
      } else {
        switch (weekday) {
          case DateTime.monday: return 'Пн';
          case DateTime.tuesday: return 'Вт';
          case DateTime.wednesday: return 'Ср';
          case DateTime.thursday: return 'Чт';
          case DateTime.friday: return 'Пт';
          case DateTime.saturday: return 'Сб';
          case DateTime.sunday: return 'Вс';
          default: return '';
        }
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
          localizations.translate('fishing_calendar'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 18.0, // Фиксированный размер без масштабирования
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis, // Обрезаем если не помещается
          maxLines: 1,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: 22.0, // Фиксированный размер
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppConstants.textColor,
              size: 22.0, // Фиксированный размер
            ),
            tooltip: localizations.translate('plan_fishing'),
            onPressed: _planNewFishing,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildCalendarHeader(),
                  _buildCalendar(),
                  SizedBox(height: ResponsiveConstants.spacingS),
                  Expanded(
                    child: _buildEventsList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final localizations = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveConstants.spacingXS,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Рассчитываем доступную ширину для каждого элемента
          final availableWidth = constraints.maxWidth;
          final itemWidth = (availableWidth - 32) / 3; // 32 = отступы между элементами

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерно распределяем
            children: [
              _buildCompactLegendItem(
                localizations.translate('past'),
                _pastFishingColor,
                itemWidth,
              ),
              _buildCompactLegendItem(
                localizations.translate('planned'),
                _futureFishingColor,
                itemWidth,
              ),
              _buildCompactLegendItem(
                localizations.translate('tournaments'),
                _tournamentColor,
                itemWidth,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactLegendItem(String label, Color color, double maxWidth) {
    return Container(
      width: maxWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.8),
                fontSize: 10.0, // Фиксированный маленький размер
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ResponsiveUtils.getResponsiveValue(context, mobile: 8.0, tablet: 10.0),
          height: ResponsiveUtils.getResponsiveValue(context, mobile: 8.0, tablet: 10.0),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: ResponsiveConstants.spacingXS),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.8),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 11).clamp(10.0, 14.0), // Ограничиваем
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final calendarHeight = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 52.0,
      tablet: 60.0,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: EdgeInsets.only(bottom: ResponsiveConstants.spacingS),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<FishingNoteModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: calendarHeight,
        daysOfWeekHeight: ResponsiveUtils.getResponsiveValue(
          context,
          mobile: 36.0,
          tablet: 40.0,
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14).clamp(12.0, 16.0), // Ограничиваем
          ),
          weekendTextStyle: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14).clamp(12.0, 16.0), // Ограничиваем
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14).clamp(12.0, 16.0), // Ограничиваем
            fontWeight: FontWeight.w600,
          ),
          todayTextStyle: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14).clamp(12.0, 16.0), // Ограничиваем
            fontWeight: FontWeight.w600,
          ),
          outsideTextStyle: TextStyle(
            color: AppConstants.textColor.withOpacity(0.3),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14).clamp(12.0, 16.0), // Ограничиваем
          ),
          defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
          weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextFormatter: (date, locale) => _getTitleText(),
          titleTextStyle: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 18).clamp(16.0, 22.0), // Ограничиваем
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context, baseSize: 24).clamp(20.0, 28.0), // Ограничиваем
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context, baseSize: 24).clamp(20.0, 28.0), // Ограничиваем
          ),
          headerPadding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingS),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0), // Ограничиваем
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0), // Ограничиваем
            fontWeight: FontWeight.w500,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppConstants.textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            return _buildDayOfWeekWidget(day);
          },
          headerTitleBuilder: (context, date) {
            return InkWell(
              onTap: _showMonthYearPicker,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveConstants.spacingS,
                  horizontal: ResponsiveConstants.spacingM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getTitleText(),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: ResponsiveUtils.getOptimalFontSize(context, 18).clamp(16.0, 22.0), // Ограничиваем
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: ResponsiveConstants.spacingS),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppConstants.textColor,
                      size: ResponsiveUtils.getIconSize(context, baseSize: 24),
                    ),
                  ],
                ),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            final fishingEvents = _getEventsForDay(day);
            final calendarEvents = _getCalendarEventsForDay(day);

            if (fishingEvents.isEmpty && calendarEvents.isEmpty) return null;

            final markerSize = ResponsiveUtils.getResponsiveValue(context, mobile: 7.0, tablet: 8.0);

            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (fishingEvents.isNotEmpty)
                    Container(
                      width: markerSize,
                      height: markerSize,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: _isPastFishing(day) ? _pastFishingColor : _futureFishingColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (calendarEvents.isNotEmpty)
                    Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: _tournamentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildDayOfWeekWidget(DateTime day) {
    final screenWidth = MediaQuery.of(context).size.width;

    String text;
    if (screenWidth < 350) {
      text = _getDayOfWeekText(day.weekday, short: true);
    } else {
      text = _getDayOfWeekText(day.weekday);
    }

    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return Container(
      height: ResponsiveUtils.getResponsiveValue(context, mobile: 20.0, tablet: 24.0), // Еще меньше высота
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 1), // Минимальный отступ
      child: Text(
        text,
        style: TextStyle(
          color: isWeekend
              ? AppConstants.textColor.withOpacity(0.9)
              : AppConstants.textColor.withOpacity(0.7),
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 9.0).clamp(8.0, 12.0), // Еще меньше шрифт дней недели
          fontWeight: isWeekend ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final localizations = AppLocalizations.of(context);
    final eventsForDay = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    final calendarEventsForDay = _selectedDay != null ? _getCalendarEventsForDay(_selectedDay!) : [];

    if (eventsForDay.isEmpty && calendarEventsForDay.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppConstants.textColor.withOpacity(0.3),
                size: ResponsiveUtils.getIconSize(context, baseSize: 40).clamp(32.0, 48.0),
              ),
              SizedBox(height: ResponsiveConstants.spacingM),
              Text(
                _selectedDay != null
                    ? localizations.translate('no_fishing_on_date')
                    : localizations.translate('select_date_to_view'),
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 15).clamp(13.0, 17.0),
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedDay != null && _selectedDay!.isAfter(DateTime.now())) ...[
                SizedBox(height: ResponsiveConstants.spacingL),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    minimumSize: Size(
                      ResponsiveConstants.minTouchTarget,
                      ResponsiveConstants.minTouchTarget,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusL),
                      ),
                    ),
                  ),
                  onPressed: () => _planNewFishingForDate(_selectedDay!),
                  icon: Icon(
                    Icons.add,
                    size: ResponsiveUtils.getIconSize(context, baseSize: 18).clamp(16.0, 20.0),
                  ),
                  label: Text(
                    localizations.translate('plan_fishing_for_date'),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 13).clamp(11.0, 15.0),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.getHorizontalPadding(context),
        ResponsiveConstants.spacingXS,
        ResponsiveUtils.getHorizontalPadding(context),
        ResponsiveConstants.spacingL, // Меньше отступ снизу
      ),
      children: [
        // Рыбалки
        ...eventsForDay.map((note) => _buildEventCard(note)),
        // Турниры
        ...calendarEventsForDay.map((event) => _buildTournamentEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(FishingNoteModel note) {
    final localizations = AppLocalizations.of(context);
    final isPast = _isPastFishing(note.date);
    final statusColor = isPast ? _pastFishingColor : _futureFishingColor;
    final statusText = isPast
        ? localizations.translate('past')
        : localizations.translate('planned');

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingS), // Меньше отступ
      child: Card(
        color: const Color(0xFF12332E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        child: InkWell(
          onTap: () => _viewNoteDetails(note),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          child: Container(
            constraints: BoxConstraints(
              minHeight: ResponsiveConstants.minTouchTarget, // Минимальная высота для touch
            ),
            padding: EdgeInsets.all(ResponsiveConstants.spacingS), // Меньше padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Важно!
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.location,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 15).clamp(13.0, 17.0),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveConstants.spacingXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 10).clamp(9.0, 12.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveConstants.spacingXS),
                Text(
                  note.isMultiDay
                      ? DateFormatter.formatDateRange(note.date, note.endDate!, context)
                      : DateFormatter.formatDate(note.date, context),
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 13).clamp(11.0, 15.0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveConstants.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.water,
                      color: AppConstants.textColor.withOpacity(0.7),
                      size: ResponsiveUtils.getIconSize(context, baseSize: 14).clamp(12.0, 16.0),
                    ),
                    SizedBox(width: ResponsiveConstants.spacingXS),
                    Expanded(
                      child: Text(
                        localizations.translate(note.fishingType),
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPast && note.biteRecords.isNotEmpty) ...[
                      SizedBox(width: ResponsiveConstants.spacingS),
                      Icon(
                        Icons.set_meal,
                        color: AppConstants.textColor.withOpacity(0.7),
                        size: ResponsiveUtils.getIconSize(context, baseSize: 14).clamp(12.0, 16.0),
                      ),
                      SizedBox(width: ResponsiveConstants.spacingXS),
                      Text(
                        '${note.biteRecords.length}',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentEventCard(CalendarEvent event) {
    final localizations = AppLocalizations.of(context);
    final isPast = event.endDate.isBefore(DateTime.now());
    final statusColor = _tournamentColor;
    final statusText = isPast
        ? localizations.translate('completed')
        : localizations.translate('tournament');

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveConstants.spacingS), // Меньше отступ
      child: Card(
        color: const Color(0xFF12332E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
        ),
        child: InkWell(
          onTap: () => _viewTournamentDetails(event),
          onLongPress: () => _showTournamentEventOptions(context, event, localizations),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
          ),
          child: Container(
            constraints: BoxConstraints(
              minHeight: ResponsiveConstants.minTouchTarget, // Минимальная высота для touch
            ),
            padding: EdgeInsets.all(ResponsiveConstants.spacingS), // Меньше padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Важно!
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 15).clamp(13.0, 17.0),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveConstants.spacingXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(ResponsiveConstants.radiusS),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: ResponsiveUtils.getOptimalFontSize(context, 10).clamp(9.0, 12.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.location != null) ...[
                  SizedBox(height: ResponsiveConstants.spacingXS),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppConstants.textColor.withOpacity(0.7),
                        size: ResponsiveUtils.getIconSize(context, baseSize: 14).clamp(12.0, 16.0),
                      ),
                      SizedBox(width: ResponsiveConstants.spacingXS),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.description != null) ...[
                  SizedBox(height: ResponsiveConstants.spacingXS),
                  Text(
                    event.description!,
                    maxLines: 1, // Только одна строка
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.6),
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 12).clamp(10.0, 14.0),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                SizedBox(height: ResponsiveConstants.spacingXS),
                Text(
                  localizations.translate('tap_for_details'),
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.5),
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 10).clamp(8.0, 12.0),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTournamentEventOptions(
      BuildContext context,
      CalendarEvent event,
      AppLocalizations localizations,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusXL),
          ),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: ResponsiveConstants.spacingM),
              Text(
                event.title,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveConstants.spacingL),

              // Кнопка просмотра деталей
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: AppConstants.primaryColor,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                title: Text(
                  localizations.translate('view_details'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewTournamentDetails(event);
                },
              ),

              // Кнопка удаления из календаря
              ListTile(
                leading: Icon(
                  Icons.event_busy,
                  color: Colors.red,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                title: Text(
                  localizations.translate('remove_from_calendar'),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeTournamentFromCalendar(context, event, localizations);
                },
              ),

              SizedBox(height: ResponsiveConstants.spacingS),

              // Кнопка отмены
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      ResponsiveConstants.minTouchTarget,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.translate('cancel'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveConstants.spacingS),
            ],
          ),
        );
      },
    );
  }

  void _removeTournamentFromCalendar(
      BuildContext context,
      CalendarEvent event,
      AppLocalizations localizations,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('remove_from_calendar'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.translate('remove_tournament_confirmation'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size(
                ResponsiveConstants.minTouchTarget,
                ResponsiveConstants.minTouchTarget,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.translate('cancel'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size(
                ResponsiveConstants.minTouchTarget,
                ResponsiveConstants.minTouchTarget,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.translate('remove'),
              style: TextStyle(
                color: Colors.red,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarEventService.removeEvent(event.id);
        await _loadFishingNotes();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('tournament_removed_from_calendar'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
}