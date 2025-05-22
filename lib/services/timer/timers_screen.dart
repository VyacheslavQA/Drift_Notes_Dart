// Путь: lib/screens/timer/timers_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/timer_provider.dart';
import '../../models/timer_model.dart';
import '../../utils/navigation.dart';
import '../../screens/timer/timer_settings_screen.dart';
import '../../localization/app_localizations.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({Key? key}) : super(key: key);

  @override
  _TimersScreenState createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  late TimerProvider _timerProvider;
  final List<StreamSubscription> _subscriptions = [];

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
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
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
                  color: Colors.green,
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
              value: currentDuration.inSeconds / 3600, // Прогресс до 1 часа
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
                        _timerProvider.startTimer(timer.id);
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
                      timer.isRunning
                          ? localizations.translate('stop')
                          : localizations.translate('start'),
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