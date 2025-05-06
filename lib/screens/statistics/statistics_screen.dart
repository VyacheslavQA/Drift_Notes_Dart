// Путь: lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/statistics_models.dart';
import '../../providers/statistics_provider.dart';
import '../../repositories/fishing_note_repository.dart';
import '../../utils/date_formatter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  // Контроллер анимации для плавного появления элементов
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Настройка анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Инициализируем провайдер статистики, если нужно
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      if (provider.statistics.hasNoData && !provider.isLoading) {
        provider.loadData();
      }
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Статистика',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 24,
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
            icon: Icon(Icons.refresh, color: AppConstants.textColor),
            onPressed: () {
              final provider = Provider.of<StatisticsProvider>(context, listen: false);
              provider.loadData();
            },
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: AppConstants.textColor,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          // Основной контент
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Блок фильтрации по периоду
                  _buildPeriodFilter(provider),
                  const SizedBox(height: 20),

                  // Если нет данных
                  if (provider.statistics.hasNoData)
                    _buildNoDataState()
                  else
                  // Блоки статистики
                    _buildStatisticsBlocks(provider.statistics),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Виджет фильтрации по периоду
  Widget _buildPeriodFilter(StatisticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Период',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Кнопки предустановленных интервалов
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                _buildPeriodButton(
                  'Неделя',
                  provider.selectedPeriod == StatisticsPeriod.week,
                      () => provider.changePeriod(StatisticsPeriod.week),
                ),
                const SizedBox(width: 12),
                _buildPeriodButton(
                  'Месяц',
                  provider.selectedPeriod == StatisticsPeriod.month,
                      () => provider.changePeriod(StatisticsPeriod.month),
                ),
                const SizedBox(width: 12),
                _buildPeriodButton(
                  'Год',
                  provider.selectedPeriod == StatisticsPeriod.year,
                      () => provider.changePeriod(StatisticsPeriod.year),
                ),
                const SizedBox(width: 12),
                _buildPeriodButton(
                  'Всё время',
                  provider.selectedPeriod == StatisticsPeriod.allTime,
                      () => provider.changePeriod(StatisticsPeriod.allTime),
                ),
                const SizedBox(width: 12),
                _buildPeriodButton(
                  'Интервал',
                  provider.selectedPeriod == StatisticsPeriod.custom,
                      () => provider.changePeriod(StatisticsPeriod.custom),
                ),
              ],
            ),
          ),
        ),

        // Блок выбора пользовательского интервала
        if (provider.selectedPeriod == StatisticsPeriod.custom)
          _buildCustomDateRangePicker(provider),
      ],
    );
  }

  // Кнопка выбора периода
  Widget _buildPeriodButton(String text, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor
                  : Colors.grey.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: AppConstants.textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Виджет выбора пользовательского интервала
  Widget _buildCustomDateRangePicker(StatisticsProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите интервал дат',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'С даты',
                  provider.customDateRange.startDate,
                      (newDate) {
                    if (newDate != null) {
                      // Если новая дата начала позже текущей даты окончания,
                      // устанавливаем дату окончания равной дате начала
                      final endDate = newDate.isAfter(provider.customDateRange.endDate)
                          ? newDate
                          : provider.customDateRange.endDate;

                      provider.updateCustomDateRange(newDate, endDate);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  'По дату',
                  provider.customDateRange.endDate,
                      (newDate) {
                    if (newDate != null) {
                      // Если новая дата окончания раньше текущей даты начала,
                      // устанавливаем дату начала равной дате окончания
                      final startDate = newDate.isBefore(provider.customDateRange.startDate)
                          ? newDate
                          : provider.customDateRange.startDate;

                      provider.updateCustomDateRange(startDate, newDate);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Виджет для выбора даты
  Widget _buildDatePicker(String label, DateTime initialDate, ValueChanged<DateTime?> onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppConstants.primaryColor,
                      onPrimary: AppConstants.textColor,
                      surface: AppConstants.surfaceColor,
                      onSurface: AppConstants.textColor,
                    ),
                    dialogBackgroundColor: AppConstants.backgroundColor,
                  ),
                  child: child!,
                );
              },
            );
            onDateSelected(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(initialDate),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppConstants.textColor.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Виджет при отсутствии данных
  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.bar_chart,
            color: AppConstants.textColor.withOpacity(0.3),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Нет данных для статистики',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Добавьте заметки о рыбалке, чтобы увидеть статистику',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/fishing_type_selection');
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить заметку'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Блоки статистики
  Widget _buildStatisticsBlocks(FishingStatistics statistics) {
    return Column(
      children: [
        // Первый ряд: всего рыбалок и самая долгая рыбалка
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Всего рыбалок',
                statistics.totalTrips.toString(),
                DateFormatter.getFishingTripsText(statistics.totalTrips),
                Icons.directions_boat,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Самая долгая рыбалка',
                statistics.longestTripDays.toString(),
                DateFormatter.getDaysText(statistics.longestTripDays),
                Icons.timer,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Второй ряд: всего дней на рыбалке и всего рыб
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Всего дней на рыбалке',
                statistics.totalDaysOnFishing.toString(),
                DateFormatter.getDaysText(statistics.totalDaysOnFishing),
                Icons.calendar_today,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Всего поймано',
                statistics.totalFish.toString(),
                DateFormatter.getFishText(statistics.totalFish),
                Icons.set_meal,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Третий ряд: самая большая рыба (полная ширина)
        if (statistics.biggestFish != null)
          _buildDetailedStatCard(
            'Самая большая рыба',
            statistics.biggestFish!.formattedText,
            Icons.emoji_events,
            Colors.amber,
          ),
        if (statistics.biggestFish != null)
          const SizedBox(height: 16),

        // Четвертый ряд: последний выезд (полная ширина)
        if (statistics.latestTrip != null)
          _buildDetailedStatCard(
            'Последний выезд',
            statistics.latestTrip!.formattedText,
            Icons.access_time,
            Colors.teal,
          ),
        if (statistics.latestTrip != null)
          const SizedBox(height: 16),

        // Пятый ряд: лучший месяц по рыбе (полная ширина)
        if (statistics.bestMonth != null)
          _buildDetailedStatCard(
            'Лучший месяц по рыбе',
            statistics.bestMonth!.formattedText,
            Icons.insights,
            Colors.deepPurple,
          ),

        // Отступ в конце
        const SizedBox(height: 32),
      ],
    );
  }

  // Карточка статистики (маленькая)
  Widget _buildStatCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Увеличиваем вертикальный отступ
      height: 150, // Фиксированная высота для всех карточек
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерно распределяем
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24, // Увеличиваем размер иконки
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2, // Разрешаем 2 строки для заголовка
                  overflow: TextOverflow.ellipsis, // Добавляем многоточие, если текст не помещается
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 40, // Увеличиваем размер основного значения
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 16, // Увеличиваем размер подтекста
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Карточка статистики (широкая, с детальной информацией)
  Widget _buildDetailedStatCard(
      String title,
      String content,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Увеличиваем отступы
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24, // Увеличиваем размер иконки
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontSize: 16, // Увеличиваем размер заголовка
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Увеличиваем отступ для лучшего разделения
          Padding(
            padding: const EdgeInsets.only(left: 4.0), // Уменьшаем отступ слева
            child: Text(
              content,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 22, // Оставляем такой же размер текста
                fontWeight: FontWeight.bold,
              ),
              // Убираем ограничение на количество строк
              // и позволяем тексту иметь нужную высоту
              softWrap: true,
              overflow: TextOverflow.visible, // Текст будет виден полностью
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}