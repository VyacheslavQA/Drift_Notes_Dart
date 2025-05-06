// Путь: lib/screens/fishing_note/bite_records_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Явный импорт для TextDirection
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../utils/date_formatter.dart';
import 'bite_record_screen.dart';

class BiteRecordsSection extends StatefulWidget {
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
  _BiteRecordsSectionState createState() => _BiteRecordsSectionState();
}

class _BiteRecordsSectionState extends State<BiteRecordsSection> {
  // Текущий выбранный день (индекс)
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Определяем количество дней рыбалки
    int totalDays = 1;
    List<DateTime> allDays = [];

    if (widget.note.isMultiDay && widget.note.endDate != null) {
      // Создаем список всех дней рыбалки
      DateTime currentDay = DateTime(
          widget.note.date.year,
          widget.note.date.month,
          widget.note.date.day
      );

      DateTime endDay = DateTime(
          widget.note.endDate!.year,
          widget.note.endDate!.month,
          widget.note.endDate!.day
      );

      // Добавляем все дни включительно от начальной до конечной даты
      while (!currentDay.isAfter(endDay)) {
        allDays.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }

      totalDays = allDays.length;
    } else {
      // Для однодневной рыбалки
      allDays.add(widget.note.date);
    }

    // Фильтруем записи по выбранному дню
    final selectedDayRecords = widget.note.biteRecords
        .where((record) => record.dayIndex == _selectedDayIndex)
        .toList();

    // Считаем количество пойманных рыб (с названием и весом)
    final caughtFishCount = widget.note.biteRecords
        .where((record) => record.fishType.isNotEmpty && record.weight > 0)
        .length;

    // Считаем общее количество поклевок
    final totalBitesCount = widget.note.biteRecords.length;

    // Количество непойманных рыб (просто поклевки)
    final missedBitesCount = totalBitesCount - caughtFishCount;

    // Сортируем записи по времени
    final sortedRecords = List<BiteRecord>.from(selectedDayRecords)
      ..sort((a, b) => b.time.compareTo(a.time)); // Сначала новые

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции с информацией о пойманных рыбах и поклевках
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Записи о поклёвках',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (caughtFishCount > 0)
                    Text(
                      'Поймано: ${caughtFishCount} ${DateFormatter.getFishText(caughtFishCount)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  if (missedBitesCount > 0)
                    Text(
                      'Поклёвок без поимки: $missedBitesCount',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                ],
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

        // Селектор дней рыбалки (только для многодневных рыбалок)
        if (totalDays > 1) ...[
          const SizedBox(height: 8),
          _buildDaysList(totalDays, allDays),
          const SizedBox(height: 12),
        ],

        // График поклевок
        if (sortedRecords.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'График поклёвок',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildBiteRecordsTimeline(context, sortedRecords),
        ],

        const SizedBox(height: 12),

        // Отображение списка поклёвок
        if (sortedRecords.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                totalDays > 1
                    ? 'Нет записей о поклёвках за ${_getDayName(_selectedDayIndex, allDays[_selectedDayIndex])}'
                    : 'Нет записей о поклёвках',
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

  // Метод для получения форматированного названия дня
  String _getDayName(int index, DateTime date) {
    return 'День ${index + 1} (${DateFormat('dd.MM.yyyy').format(date)})';
  }

  // Строим список дней (выпадающее меню)
  Widget _buildDaysList(int totalDays, List<DateTime> days) {
    return Container(
      width: double.infinity,
      child: DropdownButtonHideUnderline(
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<int>(
            value: _selectedDayIndex,
            isExpanded: true,
            dropdownColor: AppConstants.primaryColor,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppConstants.textColor,
            ),
            items: List.generate(totalDays, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  _getDayName(index, days[index]),
                  style: TextStyle(
                    color: AppConstants.textColor,
                  ),
                ),
              );
            }),
            onChanged: (int? value) {
              if (value != null) {
                setState(() {
                  _selectedDayIndex = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  // Добавление новой записи о поклёвке
  Future<void> _addBiteRecord(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(
          dayIndex: _selectedDayIndex,
        ),
      ),
    );

    if (result != null && result is BiteRecord) {
      widget.onAddRecord(result);
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
        widget.onDeleteRecord(record.id);
      } else if (result is BiteRecord) {
        // Если пришла обновленная запись
        widget.onUpdateRecord(result);
      }
    }
  }

  // Определяет, является ли запись пойманной рыбой или просто поклевкой
  bool _isFishCaught(BiteRecord record) {
    return record.fishType.isNotEmpty && record.weight > 0;
  }

  // Построение карточки записи о поклёвке
  Widget _buildBiteRecordCard(BuildContext context, BiteRecord record) {
    // Определяем, является ли запись пойманной рыбой или просто поклевкой
    final bool isCaught = _isFishCaught(record);

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
                        if (isCaught) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Поймана',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Поклевка',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Container(
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
                isFishCaughtCallback: _isFishCaught,
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
              widget.onDeleteRecord(record.id);
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
  final bool Function(BiteRecord) isFishCaughtCallback;

  _BiteRecordsTimelinePainter({
    required this.biteRecords,
    required this.isFishCaughtCallback,
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
    final divisions = 48; // 30-минутные интервалы
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
    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final totalMinutes = 24 * 60;
      final position = timeInMinutes / totalMinutes * size.width;

      final bool isCaught = isFishCaughtCallback(record);

      // Используем разные цвета для пойманных рыб и просто поклевок
      final Color dotColor = isCaught ? Colors.green : Colors.orange;

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      // Рисуем кружок для поклевки
      canvas.drawCircle(
        Offset(position, size.height / 2),
        7,
        dotPaint,
      );

      // Для пойманных рыб рисуем обводку, размер которой зависит от веса
      if (isCaught) {
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