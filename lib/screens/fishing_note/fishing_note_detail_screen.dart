// Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/fishing_note_model.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';
import 'photo_gallery_screen.dart';

class FishingNoteDetailScreen extends StatefulWidget {
  final String noteId;

  const FishingNoteDetailScreen({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  _FishingNoteDetailScreenState createState() => _FishingNoteDetailScreenState();
}

class _FishingNoteDetailScreenState extends State<FishingNoteDetailScreen> {
  final _fishingNoteRepository = FishingNoteRepository();

  FishingNoteModel? _note;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = await _fishingNoteRepository.getFishingNoteById(widget.noteId);

      setState(() {
        _note = note;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки заметки: $e';
        _isLoading = false;
      });
    }
  }

  void _viewPhotoGallery(int initialIndex) {
    if (_note == null || _note!.photoUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: _note!.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Путь: lib/screens/fishing_note/fishing_note_detail_screen.dart (продолжение)

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Удаление заметки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить эту заметку? Это действие нельзя отменить.',
          style: TextStyle(
            color: AppConstants.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: AppConstants.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fishingNoteRepository.deleteFishingNote(widget.noteId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заметка успешно удалена'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true); // true для обновления списка заметок
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении заметки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isLoading || _note == null
              ? 'Детали рыбалки'
              : _note!.location,
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
          if (!_isLoading && _note != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNote,
              child: const Text('Повторить'),
            ),
          ],
        ),
      )
          : _note == null
          ? const Center(child: Text('Заметка не найдена'))
          : _buildNoteDetails(),
    );
  }

  Widget _buildNoteDetails() {
    if (_note == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фотогалерея
          if (_note!.photoUrls.isNotEmpty)
            _buildPhotoGallery(),

          const SizedBox(height: 20),

          // Общая информация
          _buildInfoCard(),

          const SizedBox(height: 20),

          // Если есть погода, показываем её
          if (_note!.weather != null) ...[
            _buildWeatherCard(),
            const SizedBox(height: 20),
          ],

          // Снасти
          if (_note!.tackle.isNotEmpty) ...[
            _buildSectionHeader('Снасти'),
            _buildContentCard(_note!.tackle),
            const SizedBox(height: 20),
          ],

          // Заметки
          if (_note!.notes.isNotEmpty) ...[
            _buildSectionHeader('Заметки'),
            _buildContentCard(_note!.notes),
            const SizedBox(height: 20),
          ],

          // Поклевки
          if (_note!.biteRecords.isNotEmpty) ...[
            _buildSectionHeader('Поклевки'),
            _buildBiteRecordsSection(),
            const SizedBox(height: 20),
          ],

          // Если это карповая рыбалка, показываем кнопку "Маркерная карта"
          if (_note!.fishingType == 'Карповая рыбалка') ...[
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Маркерная карта'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: AppConstants.textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция маркерной карты будет доступна в ближайшее время'),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Фотографии'),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF12332E),
          ),
          child: PageView.builder(
            itemCount: _note!.photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewPhotoGallery(index),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: _note!.photoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Индикатор количества фотографий
        if (_note!.photoUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Свайпните для просмотра всех фотографий (${_note!.photoUrls.length})',
                style: TextStyle(
                  color: AppConstants.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тип рыбалки
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Тип рыбалки:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.fishingType,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Место
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Место:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.location,
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Даты
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Даты:',
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _note!.isMultiDay
                        ? DateFormatter.formatDateRange(_note!.date, _note!.endDate!)
                        : DateFormatter.formatDate(_note!.date),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Если есть координаты
            if (_note!.latitude != 0 && _note!.longitude != 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.map,
                    color: AppConstants.textColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Координаты:',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_note!.latitude.toStringAsFixed(6)}, ${_note!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = _note!.weather;
    if (weather == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Погода'),
        Card(
          color: const Color(0xFF12332E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        weather.isDay
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        color: weather.isDay
                            ? Colors.amber
                            : Colors.indigo[300],
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.toStringAsFixed(1)}°C, ${weather.weatherDescription}',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ощущается как ${weather.feelsLike.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              color: AppConstants.textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherInfoItem(
                      icon: Icons.air,
                      label: 'Ветер',
                      value: '${weather.windDirection}, ${weather.windSpeed} м/с',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.water_drop,
                      label: 'Влажность',
                      value: '${weather.humidity}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.speed,
                      label: 'Давление',
                      value: '${(weather.pressure / 1.333).toInt()} мм',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherInfoItem(
                      icon: Icons.cloud,
                      label: 'Облачность',
                      value: '${weather.cloudCover}%',
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.wb_twilight,
                      label: 'Восход',
                      value: weather.sunrise,
                    ),
                    _buildWeatherInfoItem(
                      icon: Icons.nights_stay,
                      label: 'Закат',
                      value: weather.sunset,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConstants.textColor.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(String content) {
    return Card(
      color: const Color(0xFF12332E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBiteRecordsSection() {
    // Сортируем записи по времени
    final sortedRecords = List<BiteRecord>.from(_note!.biteRecords)
      ..sort((a, b) => a.time.compareTo(b.time));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // График поклевок
        _buildBiteRecordsTimeline(sortedRecords),

        const SizedBox(height: 12),

        // Список поклевок
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRecords.length,
          itemBuilder: (context, index) {
            final record = sortedRecords[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFF12332E).withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  record.fishType.isEmpty
                      ? 'Поклевка #${index + 1}'
                      : record.fishType,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Время: ${DateFormat('HH:mm').format(record.time)}',
                      style: TextStyle(
                        color: AppConstants.textColor.withOpacity(0.7),
                      ),
                    ),
                    if (record.weight > 0)
                      Text(
                        'Вес: ${record.weight} кг',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                      ),
                    if (record.notes.isNotEmpty)
                      Text(
                        'Заметка: ${record.notes}',
                        style: TextStyle(
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBiteRecordsTimeline(List<BiteRecord> records) {
    // Если нет записей, не показываем график
    if (records.isEmpty) return const SizedBox();

    // Создаем временную шкалу от 00:00 до 23:59
    const hoursInDay = 24;
    const divisions = 48; // 30-минутные интервалы

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'График поклевок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF12332E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width - 50, 40),
                  painter: BiteRecordsTimelinePainter(
                    biteRecords: records,
                    divisions: divisions,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < hoursInDay; i += 3)
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
}

// Кастомный график поклевок - используем такой же как в экране добавления заметки
class BiteRecordsTimelinePainter extends CustomPainter {
  final List<BiteRecord> biteRecords;
  final int divisions;

  BiteRecordsTimelinePainter({
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