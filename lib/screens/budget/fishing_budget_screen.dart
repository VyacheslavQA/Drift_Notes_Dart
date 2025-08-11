// Путь: lib/screens/budget/fishing_budget_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_trip_model.dart';
import '../../repositories/budget_notes_repository.dart'; // ИСПРАВЛЕНО: Используем новый репозиторий
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/subscription/usage_badge.dart';
import '../../constants/subscription_constants.dart';
import '../../services/subscription/subscription_service.dart';
import '../subscription/paywall_screen.dart';
import 'add_fishing_trip_expenses_screen.dart';
import 'expense_list_screen.dart';
import 'budget_statistics_screen.dart';
import 'trip_details_screen.dart';

/// Главный экран управления бюджетом рыбалки
class FishingBudgetScreen extends StatefulWidget {
  const FishingBudgetScreen({super.key});

  @override
  State<FishingBudgetScreen> createState() => _FishingBudgetScreenState();
}

class _FishingBudgetScreenState extends State<FishingBudgetScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final BudgetNotesRepository _expenseRepository = BudgetNotesRepository(); // ИСПРАВЛЕНО: Используем репозиторий
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<FishingTripModel> _trips = [];
  FishingTripStatistics? _statistics;
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // month, year, all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ИСПРАВЛЕНО: Загрузка поездок через новый репозиторий
  Future<void> _loadTrips() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('🔄 Загружаем поездки через репозиторий...');

      // Загружаем поездки через репозиторий (с офлайн поддержкой)
      final trips = await _expenseRepository.getUserTrips();

      debugPrint('✅ Загружено поездок: ${trips.length}');

      // Выводим детали по каждой поездке
      for (final trip in trips) {
        debugPrint('  📍 Поездка: ${trip.displayTitle}');
        debugPrint('     Дата: ${trip.date}');
        debugPrint('     Расходов: ${trip.expenses?.length ?? 0}');
        debugPrint('     Общая сумма: ${trip.totalAmount}');
      }

      // Сортируем поездки по дате (новые сначала)
      trips.sort((a, b) => b.date.compareTo(a.date));

      final filteredTrips = _filterTripsByPeriod(trips, _selectedPeriod);
      final statistics = FishingTripStatistics.fromTrips(filteredTrips);

      debugPrint('📊 Статистика за период "$_selectedPeriod":');
      debugPrint('   Поездок: ${filteredTrips.length}');
      debugPrint('   Общая сумма: ${statistics.totalAmount}');

      if (mounted) {
        setState(() {
          _trips = trips;
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки поездок: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        final localizations = AppLocalizations.of(context);
        _showErrorSnackBar('${localizations.translate('data_loading_error') ?? 'Ошибка загрузки данных'}: $e');
      }
    }
  }

  List<FishingTripModel> _filterTripsByPeriod(
      List<FishingTripModel> trips,
      String period
      ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        return trips;
    }

    final filtered = trips.where((trip) =>
    trip.date.isAfter(startDate) || trip.date.isAtSameMomentAs(startDate)
    ).toList();

    debugPrint('🔍 Фильтрация по периоду "$period": ${trips.length} -> ${filtered.length} поездок');

    return filtered;
  }

  void _onPeriodChanged(String period) {
    debugPrint('📅 Изменен период фильтрации: $_selectedPeriod -> $period');
    setState(() {
      _selectedPeriod = period;
    });

    // Пересчитываем статистику без перезагрузки данных
    final filteredTrips = _filterTripsByPeriod(_trips, _selectedPeriod);
    final statistics = FishingTripStatistics.fromTrips(filteredTrips);

    setState(() {
      _statistics = statistics;
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ✅ ИСПРАВЛЕНО: Проверка лимитов через репозиторий с обновлением Provider
  void _navigateToAddExpense() async {
    debugPrint('➕ Попытка создания новой поездки...');

    // Проверяем лимиты перед созданием
    final canCreate = await _subscriptionService.canCreateContent(ContentType.budgetNotes);

    debugPrint('   Можно создать: $canCreate');

    if (!canCreate) {
      debugPrint('🚫 Превышен лимит, показываем PaywallScreen');
      _showPremiumRequired(ContentType.budgetNotes);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (result == true) {
      debugPrint('✅ Новая поездка создана, перезагружаем список');
      _loadTrips();

      // ✅ КРИТИЧЕСКИ ВАЖНО: Обновляем SubscriptionProvider
      try {
        if (mounted) {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после создания поездки');
        }
      } catch (e) {
        debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
      }
    }
  }

  void _showPremiumRequired(ContentType contentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(
          contentType: contentType.name,
        ),
      ),
    );
  }

  void _navigateToTripDetails(FishingTripModel trip) async {
    debugPrint('👁️ Открываем детали поездки: ${trip.displayTitle}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );

    if (result == true) {
      debugPrint('🔄 Поездка изменена, перезагружаем список');
      _loadTrips();

      // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider после изменения поездки
      try {
        if (mounted) {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
          await subscriptionProvider.refreshUsageData();
          debugPrint('✅ SubscriptionProvider обновлен после изменения поездки');
        }
      } catch (e) {
        debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: ResponsiveText(
                localizations.translate('fishing_budget') ?? 'Бюджет рыбалки',
                type: ResponsiveTextType.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            // ✅ ИСПРАВЛЕНО: UsageBadge обновляется через Consumer
            Consumer<SubscriptionProvider>(
              builder: (context, subscriptionProvider, child) {
                return UsageBadge(
                  contentType: ContentType.budgetNotes,
                  fontSize: ResponsiveUtils.isTablet(context) ? 14 : 12,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.isTablet(context) ? 10 : 8,
                    vertical: ResponsiveUtils.isTablet(context) ? 6 : 4,
                  ),
                  showIcon: true,
                  showPercentage: false,
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: () async {
              await _loadTrips();

              // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider при обновлении
              try {
                if (mounted) {
                  final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
                  await subscriptionProvider.refreshUsageData();
                  debugPrint('✅ SubscriptionProvider обновлен при обновлении экрана');
                }
              } catch (e) {
                debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
              }
            },
            tooltip: localizations.translate('refresh') ?? 'Обновить',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.textColor,
          unselectedLabelColor: AppConstants.textColor.withOpacity(0.6),
          indicatorColor: AppConstants.primaryColor,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('overview') ?? 'Обзор',
            ),
            Tab(
              icon: Icon(Icons.list, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('expenses') ?? 'Расходы',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: ResponsiveUtils.getIconSize(context, baseSize: 20)),
              text: localizations.translate('analytics') ?? 'Аналитика',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final localizations = AppLocalizations.of(context);

    return ResponsiveContainer(
      type: ResponsiveContainerType.page,
      useSafeArea: true,
      addHorizontalPadding: true,
      addVerticalPadding: true,
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadTrips();

          // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider при pull-to-refresh
          try {
            if (mounted) {
              final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
              await subscriptionProvider.refreshUsageData();
              debugPrint('✅ SubscriptionProvider обновлен при pull-to-refresh');
            }
          } catch (e) {
            debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentTrips(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ExpenseListScreen(
      onExpenseUpdated: () async {
        await _loadTrips();

        // ✅ ДОБАВЛЕНО: Обновляем SubscriptionProvider при изменении расходов
        try {
          if (mounted) {
            final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
            await subscriptionProvider.refreshUsageData();
            debugPrint('✅ SubscriptionProvider обновлен при изменении расходов');
          }
        } catch (e) {
          debugPrint('❌ Ошибка обновления SubscriptionProvider: $e');
        }
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return BudgetStatisticsScreen(
      statistics: _statistics,
    );
  }

  Widget _buildSummaryCard() {
    final localizations = AppLocalizations.of(context);
    final statistics = _statistics;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
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
          Text(
            localizations.translate('total_expenses') ?? 'Общие расходы',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Большая сумма без символа валюты
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatLargeAmount(statistics?.totalAmount ?? 0),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPeriodButton('month', localizations.translate('month') ?? 'Месяц'),
        _buildPeriodButton('year', localizations.translate('year') ?? 'Год'),
        _buildPeriodButton('all', localizations.translate('all_time') ?? 'Всё время'),
      ],
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () => _onPeriodChanged(period),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppConstants.textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final localizations = AppLocalizations.of(context);
    final statistics = _statistics;

    if (statistics == null) return const SizedBox.shrink();

    final filteredTrips = _filterTripsByPeriod(_trips, _selectedPeriod);
    final tripCount = filteredTrips.length;
    final avgPerTrip = tripCount > 0 ? (statistics.totalAmount / tripCount).toDouble() : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            localizations.translate('avg_per_trip') ?? 'Средняя за поездку',
            _formatLargeAmount(avgPerTrip),
          ),
        ),
        Expanded(
          child: _buildStatItem(
            localizations.translate('trips_count') ?? 'Количество поездок',
            tripCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        // Значение с адаптивным размером
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        // Подпись
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.textColor.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _navigateToAddExpense,
          icon: const Icon(Icons.add_card, size: 24),
          label: Text(
            localizations.translate('add_expense') ?? 'Добавить расход',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTrips() {
    final localizations = AppLocalizations.of(context);
    final recentTrips = _filterTripsByPeriod(_trips, _selectedPeriod)
        .take(5)
        .toList();

    if (recentTrips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              localizations.translate('recent_expenses') ?? 'Последние расходы',
              type: ResponsiveTextType.titleMedium,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.directions_boat, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  ResponsiveText(
                    localizations.translate('no_expenses_yet') ?? 'Пока нет расходов',
                    type: ResponsiveTextType.caption,
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    localizations.translate('add_first_expense_hint') ?? 'Нажмите "Добавить расход" чтобы создать первую запись',
                    type: ResponsiveTextType.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            localizations.translate('recent_expenses') ?? 'Последние расходы',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          ...recentTrips.map((trip) => _buildTripItem(trip)).toList(),
        ],
      ),
    );
  }

  Widget _buildTripItem(FishingTripModel trip) {
    final totalAmount = trip.totalAmount;
    final expenseCount = trip.expenses?.length ?? 0;

    return InkWell(
      onTap: () => _navigateToTripDetails(trip),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Первая строка: название + стрелка
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.displayTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppConstants.textColor.withOpacity(0.5),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Вторая строка: дата + количество расходов
            Row(
              children: [
                Text(
                  _formatDate(trip.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (expenseCount > 0) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.textColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    '$expenseCount ${_getExpenseCountText(expenseCount)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Третья строка: сумма без символа валюты
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatFullAmount(totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullAmount(double amount) {
    // Форматируем полные суммы с разделителями тысяч
    final formatter = amount.toStringAsFixed(0);
    final chars = formatter.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add(' ');
      }
      result.add(chars[i]);
    }

    return result.reversed.join();
  }

  String _formatLargeAmount(double amount) {
    // Форматируем большие суммы для статистики без символа валюты
    return _formatFullAmount(amount);
  }

  String _getExpenseCountText(int count) {
    final localizations = AppLocalizations.of(context);

    if (count == 1) {
      return localizations.translate('expense_single') ?? 'расход';
    } else if (count >= 2 && count <= 4) {
      return localizations.translate('expense_few') ?? 'расхода';
    } else {
      return localizations.translate('expense_many') ?? 'расходов';
    }
  }

  String _formatDate(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localizations.translate('today') ?? 'Сегодня';
    } else if (dateOnly == yesterday) {
      return localizations.translate('yesterday') ?? 'Вчера';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}';
    }
  }
}