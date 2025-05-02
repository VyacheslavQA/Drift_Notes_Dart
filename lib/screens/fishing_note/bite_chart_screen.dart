// Путь: lib/screens/fishing_note/bite_chart_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_bite_chart_model.dart';

class BiteChartScreen extends StatefulWidget {
  final Map<String, dynamic>? initialChart;
  final int dayIndex;
  final String dayLabel;

  const BiteChartScreen({
    Key? key,
    this.initialChart,
    required this.dayIndex,
    required this.dayLabel,
  }) : super(key: key);

  @override
  _BiteChartScreenState createState() => _BiteChartScreenState();
}

class _BiteChartScreenState extends State<BiteChartScreen> {
  late String _selectedChartType;
  late Map<String, double> _biteIntensityData;
  final TextEditingController _notesController = TextEditingController();
  bool _isEditing = false;
  String _chartId = '';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialChart != null;

    if (_isEditing) {
      _chartId = widget.initialChart!['id'] ?? const Uuid().v4();
      _selectedChartType = widget.initialChart!['chartType'] ?? 'normal';

      // Загружаем данные интенсивности клёва
      Map<String, double> intensityData = {};
      if (widget.initialChart!['biteIntensityByHour'] != null) {
        final dataMap = widget.initialChart!['biteIntensityByHour'] as Map<String, dynamic>;
        dataMap.forEach((key, value) {
          intensityData[key] = (value is double) ? value : (value as num).toDouble();
        });
        _biteIntensityData = intensityData;
      } else {
        _biteIntensityData = Map<String, double>.from(
            FishingBiteChartModel.chartTemplates[_selectedChartType] ??
                FishingBiteChartModel.chartTemplates['normal']!);
      }

      _notesController.text = widget.initialChart!['notes'] ?? '';
    } else {
      _chartId = const Uuid().v4();
      _selectedChartType = 'normal';
      _biteIntensityData = Map<String, double>.from(
          FishingBiteChartModel.chartTemplates['normal']!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Применение выбранного шаблона
  void _applyTemplate(String templateKey) {
    setState(() {
      _selectedChartType = templateKey;
      _biteIntensityData = Map<String, double>.from(
          FishingBiteChartModel.chartTemplates[templateKey]!);
    });
  }

  // Сохранение графика
  void _saveChart() {
    final chartData = {
      'id': _chartId,
      'dayIndex': widget.dayIndex,
      'chartType': _selectedChartType,
      'chartName': FishingBiteChartModel.chartTemplateNames[_selectedChartType] ?? 'Обычный клёв',
      'biteIntensityByHour': _biteIntensityData,
      'notes': _notesController.text.trim(),
    };

    Navigator.pop(context, chartData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактирование графика' : 'Новый график клёва',
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
            icon: Icon(Icons.check, color: AppConstants.textColor),
            onPressed: _saveChart,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Отображаем, для какого дня создается график
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppConstants.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'День рыбалки: ${widget.dayLabel}',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Визуализация графика
            _buildBiteChart(),

            const SizedBox(height: 20),

            // Выбор шаблона графика
            _buildSectionHeader('Выберите шаблон графика'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: FishingBiteChartModel.chartTemplates.keys.map((templateKey) {
                return _buildTemplateButton(
                    templateKey,
                    FishingBiteChartModel.chartTemplateNames[templateKey] ?? 'Шаблон'
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Заметки к графику
            _buildSectionHeader('Заметки к графику (опционально)'),
            TextFormField(
              controller: _notesController,
              style: TextStyle(color: AppConstants.textColor),
              decoration: InputDecoration(
                fillColor: const Color(0xFF12332E),
                filled: true,
                hintText: 'Введите заметки о клёве (например: "Хорошо клевало на кукурузу")',
                hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            // Кнопка сохранения
            ElevatedButton(
              onPressed: _saveChart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _isEditing ? 'СОХРАНИТЬ ИЗМЕНЕНИЯ' : 'СОХРАНИТЬ ГРАФИК КЛЁВА',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Построение визуализации графика
  Widget _buildBiteChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('График интенсивности клёва'),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _BiteChartPainter(
              biteIntensity: _biteIntensityData,
              barColor: _getChartColor(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            FishingBiteChartModel.chartTemplateNames[_selectedChartType] ?? 'Обычный клёв',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Цвет для графика в зависимости от шаблона
  Color _getChartColor() {
    switch (_selectedChartType) {
      case 'morning':
        return Colors.orange;
      case 'evening':
        return Colors.deepPurple;
      case 'noon':
        return Colors.amber;
      case 'night':
        return Colors.blue;
      case 'weak':
        return Colors.grey;
      case 'active':
        return Colors.green;
      default:
        return AppConstants.primaryColor;
    }
  }

  // Построение кнопки для выбора шаблона
  Widget _buildTemplateButton(String templateKey, String templateName) {
    final isSelected = _selectedChartType == templateKey;

    return GestureDetector(
      onTap: () => _applyTemplate(templateKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : const Color(0xFF12332E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppConstants.textColor
                : Colors.transparent,
          ),
        ),
        child: Text(
          templateName,
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Класс для отрисовки графика клёва
class _BiteChartPainter extends CustomPainter {
  final Map<String, double> biteIntensity;
  final Color barColor;

  _BiteChartPainter({
    required this.biteIntensity,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Рисуем координатную сетку
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );

    // Рисуем вертикальные линии (часы)
    final hourWidth = size.width / 24;
    for (int i = 0; i <= 24; i++) {
      final x = i * hourWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      // Добавляем подписи для часов (каждые 4 часа)
      if (i % 4 == 0 && i < 24) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i:00',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, size.height + 5));
      }
    }

    // Рисуем столбики интенсивности клёва
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    biteIntensity.forEach((hour, intensity) {
      final hourInt = int.tryParse(hour) ?? 0;
      final x = hourInt * hourWidth;
      final barHeight = intensity * size.height;

      // Рисуем столбик
      canvas.drawRect(
        Rect.fromLTWB(
          x,
          size.height - barHeight,
          x + hourWidth,
          size.height,
        ),
        barPaint,
      );

      // Рисуем обводку столбика
      canvas.drawRect(
        Rect.fromLTWB(
          x,
          size.height - barHeight,
          x + hourWidth,
          size.height,
        ),
        Paint()
          ..color = barColor.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    });
  }

  // Путь: lib/screens/fishing_note/bite_chart_screen.dart (продолжение)

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}