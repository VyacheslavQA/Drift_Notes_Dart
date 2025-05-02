// Путь: lib/screens/fishing_note/bite_records_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Явный импорт для TextDirection
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../utils/date_formatter.dart';
import 'bite_record_screen.dart';

class BiteRecordsSection extends StatelessWidget {
  final FishingNoteModel note;
  final Function(BiteRecord) onAddRecord;
  final Function(BiteRecord) onUpdateRecord;
  final Function(String) onDeleteRecord;

  const BiteRecordsSection({
    Key? key,
    required this.note,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Сортируем записи по времени
    final sortedRecords = List<BiteRecord>.from(note.biteRecords)
      ..sort((a, b) => b.time.compareTo(a.time)); // Сначала новые

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Записи о поклёвках',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _addBiteRecord(context),
            ),
          ],
        ),

        // График поклевок
        if (sortedRecords.isNotEmpty)
          _buildBiteRecordsTimeline(context, sortedRecords),

        const SizedBox(height: 12),

        // Отображение списка поклёвок
        if (sortedRecords.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Нет записей о поклёвках',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          Column(
            children: sortedRecords.map((record) => _buildBiteRecordCard(context, record)).toList(),
          ),
      ],
    );
  }

  // Добавление новой записи о поклёвке
  Future<void> _addBiteRecord(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BiteRecordScreen(),
      ),
    );

    if (result != null && result is BiteRecord) {
      onAddRecord(result);
    }
  }

  // Редактирование записи о поклёвке
  Future<void> _editBiteRecord(BuildContext context, BiteRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(
          initialRecord: record,
          dayIndex: record.dayIndex,
        ),
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        // Если пришла команда удаления
        onDeleteRecord(record.id);
      } else if (result is BiteRecord) {
        // Если пришла обновленная запись
        onUpdateRecord(result);
      }
    }
  }

  // Построение карточки записи о поклёвке
  Widget _buildBiteRecordCard(BuildContext context, BiteRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editBiteRecord(context, record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с временем и типом рыбы
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppConstants.textColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(record.time),
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (record.fishType.isNotEmpty)
                    Expanded(
                      child: Text(
                        record.fishType,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Информация о весе и длине
              if (record.weight > 0 || record.length > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      if (record.weight > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.scale,
                              color: AppConstants.textColor.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${record.weight} кг',
                              style: TextStyle(
                                color: AppConstants.textColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      if (record.weight > 0 && record.length > 0)
                        const SizedBox(width: 16),
                      if (record.length > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: AppConstants.textColor.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${record.length} см',
                              style: TextStyle(
                                color: AppConstants.textColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              // Примечания
              if (record.notes.isNotEmpty)
                Text(
                  record.notes,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),

              // Фотографии
              if (record.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: record.photoUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(record.photoUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Иконки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: AppConstants.textColor.withOpacity(0.7),
                      size: 20,
                    ),
                    tooltip: 'Редактировать',
                    onPressed: () => _editBiteRecord(context, record),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Удалить',
                    onPressed: () => _confirmDeleteRecord(context, record),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Построение графика поклёвок
  Widget _buildBiteRecordsTimeline(BuildContext context, List<BiteRecord> records) {
    // Если нет записей, не показываем график
    if (records.isEmpty) return const SizedBox();

    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text(
            'График поклёвок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 130,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width - 50, 80),
                  painter: _BiteRecordsTimelinePainter(
                    biteRecords: records,
                    divisions: divisions,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i <= hoursInDay; i += 4)
                    Text(
                      '$i:00',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Диалог подтверждения удаления записи
  void _confirmDeleteRecord(BuildContext context, BiteRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Удалить запись о поклёвке?',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить эту запись о поклёвке? Это действие нельзя отменить.',
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
              onDeleteRecord(record.id);
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
}

// Класс для отрисовки графика поклевок (таймлайна)
class _BiteRecordsTimelinePainter extends CustomPainter {
  final List<BiteRecord> biteRecords;
  final int divisions;

  _BiteRecordsTimelinePainter({
    required this.biteRecords,
    required this.divisions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Рисуем горизонтальную линию
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Рисуем деления
    final divisionWidth = size.width / divisions;
    for (int i = 0; i <= divisions; i++) {
      final x = i * divisionWidth;
      final height = i % 2 == 0 ? 10.0 : 5.0;

      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }

    // Рисуем точки поклевок
    final bitePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      // Рисуем кружок для поклевки
      canvas.drawCircle(
        Offset(position, size.height / 2),
        7,
        bitePaint,
      );

      // Если есть вес, рисуем размер круга в зависимости от веса
      if (record.weight > 0) {
        final weightPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        // Максимальный вес для отображения (15 кг)
        const maxWeight = 15.0;
        // Минимальный и максимальный радиус
        const minRadius = 8.0;
        const maxRadius = 18.0;

        final weight = record.weight.clamp(0.1, maxWeight);
        final radius = minRadius + (weight / maxWeight) * (maxRadius - minRadius);

        canvas.drawCircle(
          Offset(position, size.height / 2),
          radius,
          weightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}