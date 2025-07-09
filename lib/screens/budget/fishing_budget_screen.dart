// Путь: lib/screens/budget/fishing_budget_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../models/fishing_expense_model.dart';
import '../../models/fishing_trip_model.dart';
import '../../services/firebase/firebase_service.dart'; // ИЗМЕНЕНО: Убран FishingExpenseRepository
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_container.dart';
import '../../widgets/responsive/responsive_text.dart';
import '../../widgets/responsive/responsive_button.dart';
// ДОБАВЛЕНО: Импорт для UsageBadge
import '../../widgets/subscription/usage_badge.dart';
import '../../constants/subscription_constants.dart';
// ДОБАВЛЕНО: Импорт для проверки лимитов
import '../../services/subscription/subscription_service.dart';
// ДОБАВЛЕНО: Импорт PaywallScreen
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
  final FirebaseService _firebaseService = FirebaseService(); // ИЗМЕНЕНО: Используем FirebaseService вместо репозитория
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

  // ИЗМЕНЕНО: Новый метод загрузки поездок через FirebaseService
  Future<void> _loadTrips() async {
    try {
      setState(() => _isLoading = true);

      // Загружаем поездки через FirebaseService
      final tripsSnapshot = await _firebaseService.getUserFishingTrips();
      final List<FishingTripModel> trips = [];

      for (var doc in tripsSnapshot.docs) {
        try {
          final tripData = doc.data() as Map<String, dynamic>;
          tripData['id'] = doc.id; // Добавляем ID документа

          // Загружаем расходы для каждой поездки из subcollection
          final expensesSnapshot = await _firebaseService.getFishingTripExpenses(doc.id);
          final List<FishingExpenseModel> expenses = [];

          for (var expenseDoc in expensesSnapshot.docs) {
            try {
              final expenseData = expenseDoc.data() as Map<String, dynamic>;
              expenseData['id'] = expenseDoc.id;
              expenses.add(FishingExpenseModel.fromMap(expenseData));
            } catch (e) {
              debugPrint('Ошибка парсинга расхода ${expenseDoc.id}: $e');
            }
          }

          // Создаем поездку с расходами
          final trip = FishingTripModel.fromMapWithExpenses(tripData).withExpenses(expenses);
          trips.add(trip);
        } catch (e) {
          debugPrint('Ошибка парсинга поездки ${doc.id}: $e');
        }
      }

      // Сортируем поездки по дате (новые сначала)
      trips.sort((a, b) => b.date.compareTo(a.date));

      final filteredTrips = _filterTripsByPeriod(trips, _selectedPeriod);
      final statistics = FishingTripStatistics.fromTrips(filteredTrips);

      // ДОБАВЛЕНО: Обновляем лимиты подписки после загрузки поездок
      try {
        await _subscriptionService.refreshUsageLimits();
        debugPrint('✅ Лимиты подписки обновлены после загрузки поездок');
      } catch (e) {
        debugPrint('❌ Ошибка обновления лимитов: $e');
      }

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
        final localizations = AppLocalizations.of(context);
        _showErrorSnackBar('${localizations.translate('data_loading_error')}: $e');
      }
    }
  }

  // ИЗМЕНЕНО: Упрощенная проверка Firestore (теперь через новую структуру)
  Future<void> _checkFirestoreDirectly() async {
    try {
      final userId = _firebaseService.currentUserId;
      final localizations = AppLocalizations.of(context);

      if (userId == null) {
        _showErrorSnackBar(localizations.translate('user_not_authorized'));
        return;
      }

      // Проверяем новую структуру subcollections
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fishing_trips')
          .get();

      _showErrorSnackBar('Firestore: ${snapshot.docs.length} ${localizations.translate('trips')} | ${localizations.translate('locally')}: ${_trips.length} ${localizations.translate('trips')}');
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showErrorSnackBar('${localizations.translate('firestore_error')}: $e');
    }
  }

  // ИЗМЕНЕНО: Упрощенная синхронизация
  Future<void> _forceFirestoreSync() async {
    try {
      setState(() => _isLoading = true);

      // Просто перезагружаем данные из Firestore
      await _loadTrips();

      final localizations = AppLocalizations.of(context);
      _showErrorSnackBar(localizations.translate('data_synced_with_firestore'));
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showErrorSnackBar('${localizations.translate('sync_error')}: $e');
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

  // ИСПРАВЛЕНО: Добавлена проверка лимитов перед навигацией
  void _navigateToAddExpense() async {
    // Проверяем лимиты перед созданием
    final canCreate = await _subscriptionService.canCreateContent(ContentType.expenses);

    if (!canCreate) {
      // ИСПРАВЛЕНО: Используем PaywallScreen вместо самодельного диалога
      _showPremiumRequired(ContentType.expenses);
      return;
    }

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

  // ИСПРАВЛЕНО: Единый метод для показа PaywallScreen
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
        // ИСПРАВЛЕНО: Заголовок с UsageBadge
        title: Row(
          children: [
            Expanded(
              child: ResponsiveText(
                localizations.translate('fishing_budget') ?? 'Бюджет рыбалки',
                type: ResponsiveTextType.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            // ДОБАВЛЕНО: UsageBadge для расходов/поездок
            const SizedBox(width: 8),
            UsageBadge(
              contentType: ContentType.expenses,
              fontSize: ResponsiveUtils.isTablet(context) ? 14 : 12,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.isTablet(context) ? 10 : 8,
                vertical: ResponsiveUtils.isTablet(context) ? 6 : 4,
              ),
              showIcon: true,
              showPercentage: false,
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
          // Кнопка обновления
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _loadTrips,
            tooltip: localizations.translate('refresh'),
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
      // Убрали FloatingActionButton
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
              const SizedBox(height: 80), // Уменьшили отступ, так как убрали FAB
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
          Text(
            localizations.translate('total_expenses') ?? 'Общие расходы',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Большая сумма с адаптивным размером
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatLargeAmount(statistics?.totalAmount ?? 0, '₸'),
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
            _formatLargeAmount(avgPerTrip, '₸'),
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

  // ИСПРАВЛЕНО: Кнопка теперь всегда видна, но проверяет лимиты внутри
  Widget _buildQuickActions() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          // ИСПРАВЛЕНО: Кнопка всегда активна, проверка лимитов внутри _navigateToAddExpense
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

            // Третья строка: сумма на отдельной строке
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${trip.currencySymbol} ${_formatFullAmount(totalAmount)}',
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

  String _formatAmount(double amount, String currencySymbol) {
    // Форматируем суммы для карточек поездок (краткий формат)
    if (amount >= 1000000) {
      return '$currencySymbol ${(amount / 1000000).toStringAsFixed(1)}М';
    } else if (amount >= 1000) {
      return '$currencySymbol ${(amount / 1000).toStringAsFixed(0)}К';
    } else {
      return '$currencySymbol ${amount.toStringAsFixed(0)}';
    }
  }

  String _formatLargeAmount(double amount, String currencySymbol) {
    // Форматируем большие суммы для статистики (показываем полностью с разделителями)
    return '$currencySymbol ${_formatFullAmount(amount)}';
  }

  String _getExpenseCountText(int count) {
    final localizations = AppLocalizations.of(context);

    if (count == 1) {
      return localizations.translate('expense_single');
    } else if (count >= 2 && count <= 4) {
      return localizations.translate('expense_few');
    } else {
      return localizations.translate('expense_many');
    }
  }

  String _formatDate(DateTime date) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return localizations.translate('today');
    } else if (dateOnly == yesterday) {
      return localizations.translate('yesterday');
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}';
    }
  }
}