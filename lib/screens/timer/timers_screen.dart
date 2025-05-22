// Путь: lib/screens/timer/timers_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/timer_provider.dart';
import '../../models/timer_model.dart';
import 'timer_settings_screen.dart';
import '../../localization/app_localizations.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({Key? key}) : super(key: key);

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  late TimerProvider _timerProvider;
  final List<StreamSubscription> _subscriptions = [];

  // Переменные для выбора времени
  int _hours = 0;
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _timerProvider.initialize();

    // Подписка на обновления таймеров
    final subscription = _timerProvider.timersStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _subscriptions.add(subscription);
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  // Форматирование времени таймера
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  // Показать диалог выбора времени таймера
  void _showTimePickerDialog(String timerId) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          localizations.translate('select_time'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeOption(localizations.translate('30_minutes'), Duration(minutes: 30), timerId),
            _buildTimeOption(localizations.translate('1_hour'), Duration(hours: 1), timerId),
            _buildTimeOption(localizations.translate('1_5_hours'), Duration(hours: 1, minutes: 30), timerId),
            _buildTimeOption(localizations.translate('2_hours'), Duration(hours: 2), timerId),
            _buildTimeOption(localizations.translate('3_hours'), Duration(hours: 3), timerId),
            _buildTimeOption(localizations.translate('other'), null, timerId),
          ],
        ),
      ),
    );
  }

  // Построение опции времени для диалога
  Widget _buildTimeOption(String label, Duration? duration, String timerId) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(color: AppConstants.textColor),
      ),
      onTap: () {
        Navigator.pop(context);

        if (duration == null) {
          // Если выбран вариант "Другое", показываем диалог ручного ввода
          _showCustomTimePicker(timerId);
        } else {
          // Устанавливаем выбранное время и запускаем таймер
          _timerProvider.setTimerDuration(timerId, duration);
          _timerProvider.startTimer(timerId);
        }
      },
    );
  }

  // Показать диалог для выбора произвольного времени
  void _showCustomTimePicker(String timerId) {
    final localizations = AppLocalizations.of(context);

    // Сбрасываем значения часов и минут при каждом открытии диалога
    _hours = 0;
    _minutes = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.surfaceColor,
            title: Text(
              localizations.translate('set_time'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Часы
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_upward, color: AppConstants.textColor),
                          onPressed: () {
                            setDialogState(() {
                              _hours = (_hours + 1) % 24;
                            });
                          },
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hours.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_downward, color: AppConstants.textColor),
                          onPressed: () {
                            setDialogState(() {
                              _hours = (_hours - 1 + 24) % 24;
                            });
                          },
                        ),
                        Text(
                          localizations.translate('hours'),
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                      ],
                    ),
                    Text(
                      ':',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Минуты
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_upward, color: AppConstants.textColor),
                          onPressed: () {
                            setDialogState(() {
                              _minutes = (_minutes + 1) % 60;
                            });
                          },
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _minutes.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_downward, color: AppConstants.textColor),
                          onPressed: () {
                            setDialogState(() {
                              _minutes = (_minutes - 1 + 60) % 60;
                            });
                          },
                        ),
                        Text(
                          localizations.translate('minutes'),
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localizations.translate('cancel'),
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  // Проверяем, что выбрано хотя бы какое-то время
                  if (_hours > 0 || _minutes > 0) {
                    final duration = Duration(hours: _hours, minutes: _minutes);
                    _timerProvider.setTimerDuration(timerId, duration);
                    _timerProvider.startTimer(timerId);
                  } else {
                    // Показываем сообщение, если время не выбрано
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.translate('set_time_greater_than_zero'))),
                    );
                  }
                },
                child: Text(
                  localizations.translate('set'),
                  style: TextStyle(color: AppConstants.textColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final timers = _timerProvider.timers;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        title: Text(
          localizations.translate('timers'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Text(
                localizations.translate('fishing_timers'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: timers.length,
                itemBuilder: (context, index) {
                  final timer = timers[index];
                  final currentDuration = _timerProvider.getCurrentDuration(timer.id);

                  return _buildTimerCard(timer, currentDuration);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(FishingTimerModel timer, Duration currentDuration) {
    final localizations = AppLocalizations.of(context);

    // Рассчитываем прогресс для обратного отсчета
    double progressValue = 0.0;
    if (timer.isCountdown && timer.duration.inSeconds > 0) {
      progressValue = currentDuration.inSeconds / timer.duration.inSeconds;
      progressValue = progressValue.clamp(0.0, 1.0);
    } else {
      // Для обычного таймера используем прежнюю логику
      progressValue = currentDuration.inSeconds / 3600; // Прогресс до 1 часа
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              timer.name,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                _formatDuration(currentDuration),
                style: TextStyle(
                  color: timer.timerColor,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(timer.timerColor.withOpacity(0.7)),
              minHeight: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (timer.isRunning) {
                        _timerProvider.stopTimer(timer.id);
                      } else {
                        // Показываем диалог выбора времени при нажатии на Старт
                        _showTimePickerDialog(timer.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      timer.isRunning ? localizations.translate('stop') : localizations.translate('start'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _timerProvider.resetTimer(timer.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      localizations.translate('reset'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TimerSettingsScreen(timerId: timer.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}