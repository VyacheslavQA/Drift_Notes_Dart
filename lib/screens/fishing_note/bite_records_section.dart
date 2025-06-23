// Путь: lib/screens/fishing_note/bite_records_section.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../models/fishing_note_model.dart';
import '../../localization/app_localizations.dart';
import 'bite_record_screen.dart';

class BiteRecordsSection extends StatefulWidget {
  final FishingNoteModel note;
  final Function(BiteRecord) onAddRecord;
  final Function(BiteRecord) onUpdateRecord;
  final Function(String) onDeleteRecord;

  const BiteRecordsSection({
    super.key,
    required this.note,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
  });

  @override
  State<BiteRecordsSection> createState() => _BiteRecordsSectionState();
}

class _BiteRecordsSectionState extends State<BiteRecordsSection> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    // Определяем количество дней рыбалки
    int totalDays = 1;
    List<DateTime> allDays = [];

    if (widget.note.isMultiDay && widget.note.endDate != null) {
      DateTime currentDay = DateTime(
        widget.note.date.year,
        widget.note.date.month,
        widget.note.date.day,
      );

      DateTime endDay = DateTime(
        widget.note.endDate!.year,
        widget.note.endDate!.month,
        widget.note.endDate!.day,
      );

      while (!currentDay.isAfter(endDay)) {
        allDays.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }

      totalDays = allDays.length;
    } else {
      allDays.add(widget.note.date);
    }

    // Фильтруем записи по выбранному дню
    final selectedDayRecords =
    widget.note.biteRecords
        .where((record) => record.dayIndex == _selectedDayIndex)
        .toList();

    // Сортируем записи по времени
    final sortedRecords = List<BiteRecord>.from(selectedDayRecords)
      ..sort((a, b) => b.time.compareTo(a.time));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции - ИСПРАВЛЕНО: убрали кнопку отсюда
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getHorizontalPadding(context),
            vertical: ResponsiveConstants.spacingS,
          ),
          child: _buildSectionHeader(context, localizations, isSmallScreen),
        ),

        // Селектор дней - ИСПРАВЛЕНО
        if (totalDays > 1) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getHorizontalPadding(context),
            ),
            child: _buildDaysList(totalDays, allDays),
          ),
          SizedBox(height: ResponsiveConstants.spacingM),
        ],

        // Кнопка добавления - НОВОЕ МЕСТО
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getHorizontalPadding(context),
          ),
          child: _buildAddButton(context, localizations),
        ),
        SizedBox(height: ResponsiveConstants.spacingM),

        // График поклевок - ИСПРАВЛЕНО
        if (sortedRecords.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getHorizontalPadding(context),
            ),
            child: Text(
              localizations.translate('bite_chart'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: ResponsiveConstants.spacingS),
          _buildBiteRecordsTimeline(context, sortedRecords),
          SizedBox(height: ResponsiveConstants.spacingM),
        ],

        // Список записей - ИСПРАВЛЕНО
        if (sortedRecords.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveConstants.spacingXL),
              child: Text(
                totalDays > 1
                    ? '${localizations.translate('no_bite_records_day')} ${_getDayName(_selectedDayIndex, allDays[_selectedDayIndex])}'
                    : localizations.translate('no_bite_records'),
                style: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
        // ИСПРАВЛЕНО: Правильные отступы для карточек
          ...sortedRecords.map((record) => Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.getHorizontalPadding(context),
              right: ResponsiveUtils.getHorizontalPadding(context),
              bottom: ResponsiveConstants.spacingM,
            ),
            child: _buildBiteRecordCard(context, record),
          )).toList(),
      ],
    );
  }

  // ИСПРАВЛЕНО: Заголовок всегда вертикально
  Widget _buildSectionHeader(BuildContext context, AppLocalizations localizations, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок "Записи о поклевках" - УВЕЛИЧЕН
        Text(
          localizations.translate('bite_records'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 22), // Увеличено с 18 до 22
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingM),
      ],
    );
  }

  // ИСПРАВЛЕНО: Кнопка добавления как день рыбалки
  Widget _buildAddButton(BuildContext context, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.getButtonHeight(context),
      decoration: BoxDecoration(
        color: Colors.orange, // Оранжевый цвет как запрошено
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 8),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.spacingM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addBiteRecord(context),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: AppConstants.textColor,
                size: ResponsiveUtils.getIconSize(context),
              ),
              SizedBox(width: ResponsiveConstants.spacingS),
              Text(
                localizations.translate('add'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int index, DateTime date) {
    final localizations = AppLocalizations.of(context);
    return '${localizations.translate('day_fishing')} ${index + 1} (${DateFormat('dd.MM.yyyy').format(date)})';
  }

  // ИСПРАВЛЕНО: Правильный дропдаун
  Widget _buildDaysList(int totalDays, List<DateTime> days) {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.getButtonHeight(context),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 8),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.spacingM),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDayIndex,
          isExpanded: true,
          dropdownColor: AppConstants.primaryColor,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          items: List.generate(totalDays, (index) {
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                _getDayName(index, days[index]),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
    );
  }

  Future<void> _addBiteRecord(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(
          dayIndex: _selectedDayIndex,
          fishingStartDate: widget.note.date,
          fishingEndDate: widget.note.endDate,
          isMultiDay: widget.note.isMultiDay,
        ),
      ),
    );

    if (result != null && result is BiteRecord) {
      widget.onAddRecord(result);
    }
  }

  Future<void> _editBiteRecord(BuildContext context, BiteRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiteRecordScreen(
          initialRecord: record,
          dayIndex: record.dayIndex,
          fishingStartDate: widget.note.date,
          fishingEndDate: widget.note.endDate,
          isMultiDay: widget.note.isMultiDay,
        ),
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        widget.onDeleteRecord(record.id);
      } else if (result is BiteRecord) {
        widget.onUpdateRecord(result);
      }
    }
  }

  bool _isFishCaught(BiteRecord record) {
    return record.fishType.isNotEmpty && record.weight > 0;
  }

  // ИСПРАВЛЕНО: Правильная карточка записи
  Widget _buildBiteRecordCard(BuildContext context, BiteRecord record) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final bool isCaught = _isFishCaught(record);

    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
        ),
      ),
      child: InkWell(
        onTap: () => _editBiteRecord(context, record),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ИСПРАВЛЕНО: Заголовок записи
              _buildRecordHeader(context, record, isCaught, localizations, isSmallScreen),

              // Информация о весе и длине
              if (record.weight > 0 || record.length > 0) ...[
                SizedBox(height: ResponsiveConstants.spacingS),
                _buildWeightLengthInfo(context, record, localizations, isSmallScreen),
              ],

              // Примечания
              if (record.notes.isNotEmpty) ...[
                SizedBox(height: ResponsiveConstants.spacingS),
                Text(
                  record.notes,
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Фотографии
              if (record.photoUrls.isNotEmpty) ...[
                SizedBox(height: ResponsiveConstants.spacingS),
                _buildPhotosList(context, record),
              ],

              // Кнопки действий
              SizedBox(height: ResponsiveConstants.spacingS),
              _buildActionButtons(context, record, localizations),
            ],
          ),
        ),
      ),
    );
  }

  // ИСПРАВЛЕНО: Заголовок записи
  Widget _buildRecordHeader(BuildContext context, BiteRecord record, bool isCaught,
      AppLocalizations localizations, bool isSmallScreen) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Время и статус в одной строке
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context, baseSize: 16),
            ),
            SizedBox(width: ResponsiveConstants.spacingXS),
            Text(
              DateFormat('HH:mm').format(record.time),
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
              ),
            ),
            SizedBox(width: ResponsiveConstants.spacingS),
            Flexible(
              child: _buildStatusChip(context, isCaught, localizations),
            ),
          ],
        ),

        // Тип рыбы отдельной строкой если есть
        if (record.fishType.isNotEmpty) ...[
          SizedBox(height: ResponsiveConstants.spacingXS),
          Text(
            record.fishType,
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ],
    );
  }

  // ИСПРАВЛЕНО: Статус чип
  Widget _buildStatusChip(BuildContext context, bool isCaught, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.spacingS,
        vertical: ResponsiveConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: (isCaught ? Colors.green : Colors.red).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 4),
        ),
      ),
      child: Text(
        isCaught
            ? localizations.translate('fish_caught')
            : localizations.translate('bite_occurred'),
        style: TextStyle(
          color: isCaught ? Colors.green : Colors.red,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 12),
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ИСПРАВЛЕНО: Информация о весе и длине
  Widget _buildWeightLengthInfo(BuildContext context, BiteRecord record,
      AppLocalizations localizations, bool isSmallScreen) {

    final children = <Widget>[];

    if (record.weight > 0) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.scale,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: ResponsiveUtils.getIconSize(context, baseSize: 14),
            ),
            SizedBox(width: ResponsiveConstants.spacingXS),
            Text(
              '${record.weight} ${localizations.translate('kg')}',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.9),
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
              ),
            ),
          ],
        ),
      );
    }

    if (record.length > 0) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.straighten,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: ResponsiveUtils.getIconSize(context, baseSize: 14),
            ),
            SizedBox(width: ResponsiveConstants.spacingXS),
            Text(
              '${record.length} см',
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.9),
                fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
              ),
            ),
          ],
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ResponsiveConstants.spacingM,
      runSpacing: ResponsiveConstants.spacingXS,
      children: children,
    );
  }

  // ИСПРАВЛЕНО: Список фотографий
  Widget _buildPhotosList(BuildContext context, BiteRecord record) {
    final photoSize = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 60.0,
      tablet: 80.0,
    );

    return SizedBox(
      height: photoSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: record.photoUrls.length,
        separatorBuilder: (context, index) => SizedBox(width: ResponsiveConstants.spacingS),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: 6),
            ),
            child: Image.network(
              record.photoUrls[index],
              width: photoSize,
              height: photoSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: photoSize,
                  height: photoSize,
                  color: Colors.grey.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: photoSize * 0.4,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ИСПРАВЛЕНО: Кнопки действий
  Widget _buildActionButtons(BuildContext context, BiteRecord record, AppLocalizations localizations) {
    final buttonSize = ResponsiveUtils.getButtonHeight(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: IconButton(
            onPressed: () => _editBiteRecord(context, record),
            icon: Icon(
              Icons.edit,
              color: AppConstants.textColor.withValues(alpha: 0.7),
              size: ResponsiveUtils.getIconSize(context, baseSize: 18),
            ),
            tooltip: localizations.translate('edit'),
          ),
        ),
        SizedBox(width: ResponsiveConstants.spacingXS),
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: IconButton(
            onPressed: () => _confirmDeleteRecord(context, record),
            icon: Icon(
              Icons.delete,
              color: Colors.redAccent,
              size: ResponsiveUtils.getIconSize(context, baseSize: 18),
            ),
            tooltip: localizations.translate('delete'),
          ),
        ),
      ],
    );
  }

  // ИСПРАВЛЕНО: График поклевок
  Widget _buildBiteRecordsTimeline(BuildContext context, List<BiteRecord> records) {
    final timelineHeight = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 100.0,
      tablet: 120.0,
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
      ),
      height: timelineHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF12332E),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(ResponsiveConstants.spacingM),
              child: CustomPaint(
                size: Size.infinite,
                painter: _BiteRecordsTimelinePainter(
                  biteRecords: records,
                  isFishCaughtCallback: _isFishCaught,
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            ),
          ),
          // Временные метки - ИСПРАВЛЕНО: меньше меток
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.spacingM,
              vertical: ResponsiveConstants.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final hour = index * 8; // 0, 8, 16, 24
                return Text(
                  '$hour:00',
                  style: TextStyle(
                    color: AppConstants.textColor.withValues(alpha: 0.6),
                    fontSize: ResponsiveUtils.getOptimalFontSize(context, 9),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ИСПРАВЛЕНО: Диалог удаления
  void _confirmDeleteRecord(BuildContext context, BiteRecord record) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: 12),
          ),
        ),
        title: Text(
          localizations.translate('delete_bite_record'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 18),
          ),
        ),
        content: Text(
          localizations.translate('delete_bite_confirmation'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
          ),
        ),
        actions: [
          SizedBox(
            height: ResponsiveUtils.getButtonHeight(context),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations.translate('cancel'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.getButtonHeight(context),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDeleteRecord(record.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                localizations.translate('delete'),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getOptimalFontSize(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ИСПРАВЛЕНО: Painter для графика
class _BiteRecordsTimelinePainter extends CustomPainter {
  final List<BiteRecord> biteRecords;
  final bool Function(BiteRecord) isFishCaughtCallback;
  final Size screenSize;

  _BiteRecordsTimelinePainter({
    required this.biteRecords,
    required this.isFishCaughtCallback,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Основная линия времени
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.0;

    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      linePaint,
    );

    // Деления времени
    final divisionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    for (int hour = 0; hour <= 24; hour += 4) {
      final x = (hour / 24) * size.width;
      canvas.drawLine(
        Offset(x, centerY - 8),
        Offset(x, centerY + 8),
        divisionPaint,
      );
    }

    // Точки поклевок
    final dotRadius = screenSize.width > 600 ? 4.0 : 3.0;
    final maxRingRadius = screenSize.width > 600 ? 12.0 : 10.0;

    for (final record in biteRecords) {
      final timeInMinutes = record.time.hour * 60 + record.time.minute;
      final x = (timeInMinutes / (24 * 60)) * size.width;

      final bool isCaught = isFishCaughtCallback(record);
      final color = isCaught ? Colors.green : Colors.red;

      // Основная точка
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, centerY), dotRadius, dotPaint);

      // Кольцо для пойманной рыбы (размер зависит от веса)
      if (isCaught && record.weight > 0) {
        final ringPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final normalizedWeight = (record.weight / 10).clamp(0.2, 1.0);
        final ringRadius = dotRadius + 3 + (normalizedWeight * (maxRingRadius - dotRadius - 3));

        canvas.drawCircle(Offset(x, centerY), ringRadius, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}