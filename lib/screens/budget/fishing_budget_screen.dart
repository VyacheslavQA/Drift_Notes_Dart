// Путь: lib/screens/budget/fishing_budget_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../models/fishing_trip_model.dart';
import '../../repositories/fishing_expense_repository.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/responsive/responsive_button.dart';
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
  final FishingExpenseRepository _expenseRepository = FishingExpenseRepository();

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

  Future<void> _loadTrips() async {
    try {
      setState(() => _isLoading = true);

      final trips = await _expenseRepository.getUserTrips();
      final filteredTrips = _filterTripsByPeriod(trips, _selectedPeriod);
      final statistics = FishingTripStatistics.fromTrips(filteredTrips);

      if (mounted) {
        setState(() {
          _trips = trips;
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    }
  }

  Future<void> _checkFirestoreDirectly() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('fishing_trips')
          .where('userId', isEqualTo: userId)
          .get();

      _showErrorSnackBar('Firestore: ${snapshot.docs.length} поездок | Локально: ${_trips.length} поездок');
    } catch (e) {
      _showErrorSnackBar('Ошибка Firestore: $e');
    }
  }

  Future<void> _forceFirestoreSync() async {
    try {
      setState(() => _isLoading = true);

      // ТОЛЬКО очищаем локальный кеш через публичный метод репозитория
      await _expenseRepository.clearOfflineCache();

      // Загружаем заново из Firestore
      await _loadTrips();

      _showErrorSnackBar('Данные синхронизированы с Firestore (кеш обновлен)');
    } catch (e) {
      _showErrorSnackBar('Ошибка синхронизации: $e');
      setState(() => _isLoading = false);
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

    return trips.where((trip) =>
    trip.date.isAfter(startDate) || trip.date.isAtSameMomentAs(startDate)
    ).toList();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadTrips();
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

  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (result == true) {
      _loadTrips();
    }
  }

  void _navigateToTripDetails(FishingTripModel trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );

    if (result == true) {
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: ResponsiveText(
          localizations.translate('fishing_budget') ?? 'Бюджет рыбалки',
          type: ResponsiveTextType.titleLarge,
          fontWeight: FontWeight.w600,
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
          // Кнопка обновления
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _loadTrips,
            tooltip: 'Обновить',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить расходы на рыбалку',
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
        onRefresh: _loadTrips,
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
              const SizedBox(height: 100), // Отступ для FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ExpenseListScreen(
      onExpenseUpdated: _loadTrips,
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
          ResponsiveText(
            localizations.translate('total_expenses') ?? 'Общие расходы',
            type: ResponsiveTextType.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            statistics?.formattedTotal ?? '₸ 0',
            type: ResponsiveTextType.displayMedium,
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
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
    final avgPerTrip = tripCount > 0 ? statistics.totalAmount / tripCount : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            localizations.translate('avg_per_trip') ?? 'Средние за поездку',
            '₸ ${avgPerTrip.toStringAsFixed(0)}',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            localizations.translate('trips_count') ?? 'Поездок',
            tripCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        ResponsiveText(
          value,
          type: ResponsiveTextType.titleLarge,
          color: AppConstants.textColor,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveText(
          label,
          type: ResponsiveTextType.labelSmall,
          color: AppConstants.textColor.withOpacity(0.7),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add_card),
              label: Text(localizations.translate('add_expense') ?? 'Добавить расход'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement budget planning
                _showErrorSnackBar('Функция в разработке');
              },
              icon: const Icon(Icons.trending_up),
              label: Text(localizations.translate('planning') ?? 'Планирование'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: BorderSide(color: AppConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
              localizations.translate('recent_trips') ?? 'Последние поездки',
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
                    localizations.translate('no_trips_yet') ?? 'Пока нет поездок',
                    type: ResponsiveTextType.caption,
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    localizations.translate('add_first_trip') ?? 'Нажмите "+" чтобы добавить первую поездку',
                    type: ResponsiveTextType.caption,
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
            localizations.translate('recent_trips') ?? 'Последние поездки',
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_boat,
                  size: 20,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    trip.displayTitle,
                    type: ResponsiveTextType.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ResponsiveText(
                        _formatDate(trip.date),
                        type: ResponsiveTextType.labelSmall,
                        color: AppConstants.textColor.withOpacity(0.7),
                      ),
                      if (expenseCount > 0) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: AppConstants.textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        ResponsiveText(
                          '$expenseCount ${_getExpenseCountText(expenseCount)}',
                          type: ResponsiveTextType.labelSmall,
                          color: AppConstants.textColor.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ResponsiveText(
                  '${trip.currencySymbol} ${totalAmount.toStringAsFixed(0)}',
                  type: ResponsiveTextType.bodyLarge,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppConstants.textColor.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getExpenseCountText(int count) {
    if (count == 1) {
      return 'расход';
    } else if (count >= 2 && count <= 4) {
      return 'расхода';
    } else {
      return 'расходов';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Сегодня';
    } else if (dateOnly == yesterday) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}';
    }
  }
}