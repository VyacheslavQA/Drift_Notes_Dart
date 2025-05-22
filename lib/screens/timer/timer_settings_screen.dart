// Путь: lib/screens/timer/timer_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../constants/app_constants.dart';
import '../../providers/timer_provider.dart';
import '../../models/timer_model.dart';
import '../../services/timer/timer_service.dart';
import '../../localization/app_localizations.dart';

class TimerSettingsScreen extends StatefulWidget {
  final String timerId;

  const TimerSettingsScreen({
    Key? key,
    required this.timerId,
  }) : super(key: key);

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  late TimerProvider _timerProvider;
  late TextEditingController _nameController;
  late FishingTimerModel _timer;

  Color _selectedColor = Colors.green;
  String _selectedSound = 'default_alert.mp3';

  // Добавляем аудиоплеер и состояние воспроизведения для экрана настроек
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _playingSound;

  @override
  void initState() {
    super.initState();
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);

    // Находим нужный таймер
    _timer = _timerProvider.timers.firstWhere(
          (timer) => timer.id == widget.timerId,
      orElse: () => FishingTimerModel(
        id: widget.timerId,
        name: 'Таймер',
      ),
    );

    _nameController = TextEditingController(text: _timer.name);
    _selectedColor = _timer.timerColor;
    _selectedSound = _timer.alertSound;

    // Слушаем окончание воспроизведения
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingSound = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  // Сохранение настроек
  void _saveSettings() {
    // Останавливаем воспроизведение, если оно идет
    if (_playingSound != null) {
      _previewPlayer.stop();
    }

    _timerProvider.updateTimerSettings(
      widget.timerId,
      name: _nameController.text.trim(),
      timerColor: _selectedColor,
      alertSound: _selectedSound,
    );

    Navigator.of(context).pop();
  }

  // Воспроизведение или остановка звука
  void _toggleSoundPreview(String soundFile) async {
    if (_playingSound == soundFile) {
      // Если этот звук уже играет, останавливаем его
      await _previewPlayer.stop();
      setState(() {
        _playingSound = null;
      });
    } else {
      // Если играл другой звук, останавливаем его
      if (_playingSound != null) {
        await _previewPlayer.stop();
      }

      // Воспроизводим выбранный звук
      try {
        await _previewPlayer.play(AssetSource('sounds/$soundFile'));
        setState(() {
          _playingSound = soundFile;
        });
      } catch (e) {
        print("Ошибка при воспроизведении звука: $e");
        setState(() {
          _playingSound = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем локализацию в build методе
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        title: Text(
          localizations.translate('timer_settings'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () {
            // Останавливаем воспроизведение при выходе
            if (_playingSound != null) {
              _previewPlayer.stop();
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название таймера
              Text(
                localizations.translate('timer_name'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: AppConstants.textColor),
                decoration: InputDecoration(
                  fillColor: AppConstants.surfaceColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstants.textColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Выбор цвета
              Text(
                localizations.translate('timer_color'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildColorSelection(localizations),

              const SizedBox(height: 24),

              // Выбор звука
              Text(
                localizations.translate('notification_sound'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSoundSelection(localizations),

              const SizedBox(height: 32),

              // Кнопка сохранения
              Center(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    localizations.translate('save'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет выбора цвета
  Widget _buildColorSelection(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColorOption(
          TimerService.timerColors['green']!,
          localizations.translate('green'),
          _selectedColor == TimerService.timerColors['green'],
        ),
        _buildColorOption(
          TimerService.timerColors['red']!,
          localizations.translate('red'),
          _selectedColor == TimerService.timerColors['red'],
        ),
        _buildColorOption(
          TimerService.timerColors['orange']!,
          localizations.translate('orange'),
          _selectedColor == TimerService.timerColors['orange'],
        ),
        _buildColorOption(
          TimerService.timerColors['blue']!,
          localizations.translate('blue'),
          _selectedColor == TimerService.timerColors['blue'],
        ),
      ],
    );
  }

  // Опция выбора цвета
  Widget _buildColorOption(Color color, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppConstants.textColor : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Виджет выбора звука
  Widget _buildSoundSelection(AppLocalizations localizations) {
    final sounds = [
      {'name': localizations.translate('default'), 'file': 'default_alert.mp3'},
      {'name': localizations.translate('splash'), 'file': 'fish_splash.mp3'},
      {'name': localizations.translate('bell'), 'file': 'bell.mp3'},
      {'name': localizations.translate('alarm'), 'file': 'alarm.mp3'},
    ];

    return Column(
      children: sounds.map((sound) {
        final isSelected = _selectedSound == sound['file'];
        final isPlaying = _playingSound == sound['file'];

        return ListTile(
          title: Text(
            sound['name']!,
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? _selectedColor : Colors.white60,
          ),
          trailing: IconButton(
            icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_outline,
                color: isPlaying ? Colors.red : Colors.white70
            ),
            onPressed: () {
              _toggleSoundPreview(sound['file']!);

              // Показываем уведомление
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isPlaying
                      ? '${localizations.translate('stopping')}: ${sound['name']}'
                      : '${localizations.translate('playing')}: ${sound['name']}'
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          onTap: () {
            setState(() {
              _selectedSound = sound['file']!;
            });
          },
          tileColor: isSelected ? AppConstants.surfaceColor.withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}