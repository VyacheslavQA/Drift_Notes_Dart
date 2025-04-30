// Путь: lib/screens/timer/timer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/timer_provider.dart';
import '../../models/timer_model.dart';
import '../../services/timer/timer_service.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Сохранение настроек
  void _saveSettings() {
    _timerProvider.updateTimerSettings(
      widget.timerId,
      name: _nameController.text.trim(),
      timerColor: _selectedColor,
      alertSound: _selectedSound,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        title: Text(
          'Настройки таймера',
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
                'Название таймера',
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
                'Цвет таймера',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildColorSelection(),

              const SizedBox(height: 24),

              // Выбор звука
              Text(
                'Звук оповещения',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSoundSelection(),

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
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
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
  Widget _buildColorSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColorOption(
          TimerService.timerColors['green']!,
          'Зеленый',
          _selectedColor == TimerService.timerColors['green'],
        ),
        _buildColorOption(
          TimerService.timerColors['red']!,
          'Красный',
          _selectedColor == TimerService.timerColors['red'],
        ),
        _buildColorOption(
          TimerService.timerColors['orange']!,
          'Оранжевый',
          _selectedColor == TimerService.timerColors['orange'],
        ),
        _buildColorOption(
          TimerService.timerColors['blue']!,
          'Синий',
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
  Widget _buildSoundSelection() {
    final sounds = [
      {'name': 'По умолчанию', 'file': 'default_alert.mp3'},
      {'name': 'Всплеск', 'file': 'fish_splash.mp3'},
      {'name': 'Колокольчик', 'file': 'bell.mp3'},
      {'name': 'Будильник', 'file': 'alarm.mp3'},
    ];

    return Column(
      children: sounds.map((sound) {
        final isSelected = _selectedSound == sound['file'];

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
            icon: const Icon(Icons.play_circle_outline, color: Colors.white70),
            onPressed: () {
              // Здесь будет воспроизведение звука для предпросмотра
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Воспроизведение: ${sound['name']}')),
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