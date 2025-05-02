// Путь: lib/screens/fishing_note/bite_charts_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_bite_chart_model.dart';
import '../../models/fishing_note_model.dart';
import '../../utils/date_formatter.dart';
import 'bite_chart_screen.dart';

class BiteChartsSection extends StatefulWidget {
  final FishingNoteModel note;
  final Function(Map<String, dynamic>) onAddChart;
  final Function(Map<String, dynamic>) onUpdateChart;
  final Function(String) onDeleteChart;

  const BiteChartsSection({
    Key? key,
    required this.note,
    required this.onAddChart,
    required this.onUpdateChart,
    required this.onDeleteChart,
  }) : super(key: key);

  @override
  _BiteChartsSectionState createState() => _BiteChartsSectionState();
}

class _BiteChartsSectionState extends State<BiteChartsSection> {
  late List<Map<String, dynamic>> _charts;
  int _daysCount = 1;

  @override
  void initState() {
    super.initState();
    _charts = List.from(widget.note.biteCharts);
    _updateDaysCount();
  }

  // Обновление количества дней рыбалки
  void _updateDaysCount() {
    if (widget.note.isMultiDay && widget.note.endDate != null) {
      _daysCount = widget.note.endDate!.difference(widget.note.date).inDays + 1;
    } else {
      _daysCount = 1;
    }
  }

  // Получение метки для дня
  String _getDayLabel(int dayIndex) {
    if (_daysCount == 1) {
      return 'Единственный день';
    }

    final date = widget.note.date.add(Duration(days: dayIndex));
    return '${DateFormatter.formatDate(date)} (День ${dayIndex + 1})';
  }

  // Проверка, есть ли график для конкретного дня
  bool _hasChartForDay(int dayIndex) {
    return _charts.any((chart) => chart['dayIndex'] == dayIndex);
  }

  // Получение графика для конкретного дня
  Map<String, dynamic>? _getChartForDay(int dayIndex) {
    try {
      return _charts.firstWhere((chart) => chart['dayIndex'] == dayIndex);
    } catch (e) {
      return null;
    }
  }

  // Редактирование графика
  Future<void> _editChart(int dayIndex) async {
    final existingChart = _getChartForDay(dayIndex);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteChartScreen(
          initialChart: existingChart,
          dayIndex: dayIndex,
          dayLabel: _getDayLabel(dayIndex),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (existingChart != null) {
        // Обновляем существующий график
        widget.onUpdateChart(result);
      } else {
        // Добавляем новый график
        widget.onAddChart(result);
      }
    }
  }

  // Подтверждение удаления графика
  void _confirmDeleteChart(Map<String, dynamic> chart) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Удалить график?',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить этот график клёва? Это действие нельзя отменить.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteChart(chart['id']);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Графики клёва',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Список дней рыбалки и их графиков
        for (int i = 0; i < _daysCount; i++) ...[
          const SizedBox(height: 12),
          _buildDayChartCard(i),
        ],
      ],
    );
  }

  // Построение карточки для дня с графиком или кнопкой добавления
  Widget _buildDayChartCard(int dayIndex) {
    final hasChart = _hasChartForDay(dayIndex);
    final chart = _getChartForDay(dayIndex);

    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок дня
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getDayLabel(dayIndex),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasChart)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        tooltip: 'Редактировать',
                        onPressed: () => _editChart(dayIndex),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Удалить',
                        onPressed: () => _confirmDeleteChart(chart!),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Отображение графика, если он есть
          if (hasChart) ...[
            SizedBox(
              height: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CustomPaint(
                  size: const Size(double.infinity, 130),
                  painter: _BiteChartPreviewPainter(
                    biteIntensity: _getBiteIntensityFromChart(chart!),
                    barColor: _getColorForChartType(chart['chartType'] ?? 'normal'),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                chart!['chartName'] ?? 'График клёва',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Заметки к графику, если они есть
            if (chart['notes'] != null && chart['notes'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                child: Text(
                  chart['notes'],
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ] else ...[
            // Кнопка добавления графика, если его нет
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _editChart(dayIndex),
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Добавить график клёва'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Преобразование данных графика в формат для отрисовки
  Map<String, double> _getBiteIntensityFromChart(Map<String, dynamic> chart) {
    Map<String, double> result = {};

    if (chart['biteIntensityByHour'] != null) {
      final dataMap = chart['biteIntensityByHour'] as Map<String, dynamic>;
      dataMap.forEach((key, value) {
        result[key] = (value is double) ? value : (value as num).toDouble();
      });
      return result;
    }

    // Если данных нет, используем стандартный шаблон
    final chartType = chart['chartType'] ?? 'normal';
    return Map<String, double>.from(
        FishingBiteChartModel.chartTemplates[chartType] ??
            FishingBiteChartModel.chartTemplates['normal']!);
  }

  // Получение цвета для определенного типа графика
  Color _getColorForChartType(String chartType) {
    switch (chartType) {
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
}

// Класс для отрисовки предпросмотра графика
class _BiteChartPreviewPainter extends CustomPainter {
  final Map<String, double> biteIntensity;
  final Color barColor;

  _BiteChartPreviewPainter({
    required this.biteIntensity,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Рисуем основные линии графика
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

    // Рисуем столбики интенсивности клёва
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    // Вычисляем ширину столбика в зависимости от количества часов
    final hourWidth = size.width / 24;

    biteIntensity.forEach((hour, intensity) {
      final hourInt = int.tryParse(hour) ?? 0;
      final x = hourInt * hourWidth;
      final barHeight = intensity * size.height;

      // Рисуем столбик - исправленная версия для совместимости
      canvas.drawRect(
        Rect.fromPoints(
          Offset(x, size.height - barHeight),
          Offset(x + hourWidth, size.height),
        ),
        barPaint,
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}