// Путь: lib/screens/tournaments/tournaments_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/tournament_model.dart';
import '../../services/tournament_service.dart';
import '../../localization/app_localizations.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with TickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  late TabController _mainTabController;
  late TabController _officialTabController;
  late TabController _commercialTabController;

  List<TournamentModel> _allTournaments = [];
  List<TournamentModel> _officialTournaments = [];
  List<TournamentModel> _commercialTournaments = [];
  List<TournamentModel> _filteredTournaments = [];

  String _searchQuery = '';
  TournamentFilter _currentFilter = TournamentFilter.all;
  int _currentMainTab = 0; // 0 - официальные, 1 - коммерческие

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _officialTabController = TabController(length: 4, vsync: this);
    _commercialTabController = TabController(length: 4, vsync: this);

    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) {
        setState(() {
          _currentMainTab = _mainTabController.index;
        });
        _applyFilters();
      }
    });

    _loadTournaments();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _officialTabController.dispose();
    _commercialTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTournaments() {
    setState(() {
      _allTournaments = _tournamentService.getAllTournaments();
      _officialTournaments = _tournamentService.getOfficialTournaments();
      _commercialTournaments = _tournamentService.getCommercialTournaments();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<TournamentModel> baseList = _currentMainTab == 0
        ? _officialTournaments
        : _commercialTournaments;

    List<TournamentModel> filtered = baseList;

    // Применяем фильтр по времени
    switch (_currentFilter) {
      case TournamentFilter.upcoming:
        filtered = filtered.where((t) => t.isFuture).toList();
        break;
      case TournamentFilter.active:
        filtered = filtered.where((t) => t.isActive).toList();
        break;
      case TournamentFilter.past:
        filtered = filtered.where((t) => t.isPast).toList();
        break;
      case TournamentFilter.all:
        break;
    }

    // Применяем поиск
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
      t.name.toLowerCase().contains(query) ||
          t.location.toLowerCase().contains(query) ||
          t.organizer.toLowerCase().contains(query) ||
          t.discipline.displayName.toLowerCase().contains(query)
      ).toList();
    }

    // Сортируем по дате
    filtered.sort((a, b) => a.startDate.compareTo(b.startDate));

    setState(() {
      _filteredTournaments = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(TournamentFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('tournaments'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.textColor,
          unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Официальные'),
            Tab(text: 'Коммерческие'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Панель поиска
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppConstants.textColor),
              decoration: InputDecoration(
                hintText: localizations.translate('search_tournaments'),
                hintStyle: TextStyle(
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppConstants.textColor.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppConstants.textColor.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF12332E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppConstants.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Статистика
          _buildStatisticsCard(),

          const SizedBox(height: 8),

          // Вторичные вкладки (по времени)
          _buildSecondaryTabs(),

          // Список турниров
          Expanded(
            child: _buildTournamentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final localizations = AppLocalizations.of(context);
    final currentList = _currentMainTab == 0 ? _officialTournaments : _commercialTournaments;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            localizations.translate('total'),
            currentList.length.toString(),
            Icons.emoji_events,
          ),
          _buildStatItem(
            localizations.translate('upcoming'),
            currentList.where((t) => t.isFuture).length.toString(),
            Icons.schedule,
          ),
          _buildStatItem(
            localizations.translate('active'),
            currentList.where((t) => t.isActive).length.toString(),
            Icons.play_arrow,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryTabs() {
    final localizations = AppLocalizations.of(context);
    final tabController = _currentMainTab == 0 ? _officialTabController : _commercialTabController;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppConstants.primaryColor,
        labelColor: AppConstants.textColor,
        unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: [
          Tab(text: localizations.translate('all_tournaments')),
          Tab(text: localizations.translate('upcoming')),
          Tab(text: localizations.translate('active')),
          Tab(text: localizations.translate('past')),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _onFilterChanged(TournamentFilter.all);
              break;
            case 1:
              _onFilterChanged(TournamentFilter.upcoming);
              break;
            case 2:
              _onFilterChanged(TournamentFilter.active);
              break;
            case 3:
              _onFilterChanged(TournamentFilter.past);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTournamentsList() {
    if (_filteredTournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppConstants.textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_tournaments'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Группируем турниры по месяцам
    final Map<String, List<TournamentModel>> groupedTournaments = {};
    for (final tournament in _filteredTournaments) {
      final month = tournament.month;
      if (!groupedTournaments.containsKey(month)) {
        groupedTournaments[month] = [];
      }
      groupedTournaments[month]!.add(tournament);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: groupedTournaments.length,
      itemBuilder: (context, index) {
        final month = groupedTournaments.keys.elementAt(index);
        final monthTournaments = groupedTournaments[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок месяца
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                month,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Турниры месяца
            ...monthTournaments.map((tournament) => _buildTournamentCard(tournament)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: tournament.isActive
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailScreen(tournament: tournament),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка типа турнира
                    Text(
                      tournament.type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),

                    // Название и статус
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tournament.isOfficial
                                      ? Colors.blue.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tournament.isOfficial ? 'Официальный' : 'Коммерческий',
                                  style: TextStyle(
                                    color: tournament.isOfficial ? Colors.blue : Colors.orange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tournament.discipline.displayName,
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (tournament.isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'АКТИВЕН',
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Дата
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tournament.formattedDate,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${tournament.duration}ч',
                          style: TextStyle(
                            color: AppConstants.textColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Локация и организатор
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament.location,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: AppConstants.textColor.withValues(alpha: 0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament.organizer,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Сектор
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tournament.sector,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum TournamentFilter {
  all,
  upcoming,
  active,
  past,
}