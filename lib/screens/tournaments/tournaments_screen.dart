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
  late TabController _tabController;

  List<TournamentModel> _tournaments = [];
  List<TournamentModel> _filteredTournaments = [];
  String _searchQuery = '';
  TournamentFilter _currentFilter = TournamentFilter.all;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTournaments() {
    setState(() {
      _tournaments = _tournamentService.getAllTournaments();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<TournamentModel> filtered = _tournaments;

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
      case TournamentFilter.carpFishing:
        filtered = filtered.where((t) => t.fishingType == FishingType.carpFishing).toList();
        break;
      case TournamentFilter.casting:
        filtered = filtered.where((t) => t.fishingType == FishingType.casting).toList();
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
          t.organizer.toLowerCase().contains(query)
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.textColor,
          unselectedLabelColor: AppConstants.textColor.withValues(alpha: 0.6),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: localizations.translate('all_tournaments')),
            Tab(text: localizations.translate('upcoming')),
            Tab(text: localizations.translate('active')),
            Tab(text: localizations.translate('past')),
            Tab(text: localizations.translate('by_types')),
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
              case 4:
              // Покажем фильтры по типам рыбалки
                break;
            }
          },
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
          Container(
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
                  _tournaments.length.toString(),
                  Icons.emoji_events,
                ),
                _buildStatItem(
                  localizations.translate('carp_short'),
                  _tournaments.where((t) => t.fishingType == FishingType.carpFishing).length.toString(),
                  Icons.water,
                ),
                _buildStatItem(
                  localizations.translate('casting_short'),
                  _tournaments.where((t) => t.fishingType == FishingType.casting).length.toString(),
                  Icons.gps_fixed,
                ),
                _buildStatItem(
                  localizations.translate('upcoming'),
                  _tournaments.where((t) => t.isFuture).length.toString(),
                  Icons.schedule,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Список турниров
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentsList(_filteredTournaments),
                _buildTournamentsList(_tournaments.where((t) => t.isFuture).toList()),
                _buildTournamentsList(_tournaments.where((t) => t.isActive).toList()),
                _buildTournamentsList(_tournaments.where((t) => t.isPast).toList()),
                _buildFishingTypesView(),
              ],
            ),
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
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFishingTypesView() {
    final localizations = AppLocalizations.of(context);

    // Получаем все виды рыбалки, которые есть в данных
    final fishingStats = _tournamentService.getFishingTypeStatistics();

    // Определяем порядок отображения видов рыбалки
    final fishingTypesOrder = [
      FishingType.carpFishing,
      FishingType.spinning,
      FishingType.feeder,
      FishingType.iceFishing,
      FishingType.casting,
      FishingType.floatFishing,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fishingTypesOrder.map((fishingType) {
        final count = fishingStats[fishingType] ?? 0;
        final tournaments = _tournaments.where((t) => t.fishingType == fishingType).toList();

        // Показываем только те типы, для которых есть турниры
        if (count == 0) return const SizedBox.shrink();

        return Column(
          children: [
            _buildFishingTypeCard(
              fishingType,
              count,
              tournaments,
              localizations,
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFishingTypeCard(FishingType fishingType, int count, List<TournamentModel> tournaments, AppLocalizations localizations) {
    return Card(
      color: AppConstants.surfaceColor,
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            fishingType.iconPath,
            width: 24,
            height: 24,
            color: AppConstants.textColor,
            errorBuilder: (context, error, stackTrace) {
              // Fallback к эмодзи если иконка не найдена
              return Text(
                fishingType.icon,
                style: const TextStyle(fontSize: 24),
              );
            },
          ),
        ),
        title: Text(
          localizations.translate(fishingType.localizationKey),
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$count ${localizations.translate('tournaments_count')}',
          style: TextStyle(
            color: AppConstants.textColor.withValues(alpha: 0.7),
          ),
        ),
        children: tournaments.map((tournament) => ListTile(
          title: Text(
            tournament.name,
            style: TextStyle(color: AppConstants.textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${tournament.formattedDate} • ${tournament.location}',
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            tournament.category.icon,
            style: const TextStyle(fontSize: 20),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentDetailScreen(tournament: tournament),
              ),
            );
          },
        )).toList(),
      ),
    );
  }

  Widget _buildTournamentsList(List<TournamentModel> tournaments) {
    final localizations = AppLocalizations.of(context);

    if (tournaments.isEmpty) {
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
              localizations.translate('no_tournaments'),
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
    for (final tournament in tournaments) {
      final month = tournament.month;
      if (!groupedTournaments.containsKey(month)) {
        groupedTournaments[month] = [];
      }
      groupedTournaments[month]!.add(tournament);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                month,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Турниры месяца
            ...monthTournaments.map((tournament) => _buildTournamentCard(tournament, localizations)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament, AppLocalizations localizations) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Иконка типа рыбалки
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        tournament.fishingType.iconPath,
                        width: 20,
                        height: 20,
                        color: AppConstants.textColor,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback к эмодзи если иконка не найдена
                          return Text(
                            tournament.fishingType.icon,
                            style: const TextStyle(fontSize: 20),
                          );
                        },
                      ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  localizations.translate(tournament.fishingType.localizationKey),
                                  style: TextStyle(
                                    color: AppConstants.textColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tournament.category.icon,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      localizations.translate(tournament.category.localizationKey),
                                      style: TextStyle(
                                        color: AppConstants.textColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (tournament.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    localizations.translate('active').toUpperCase(),
                                    style: TextStyle(
                                      color: AppConstants.textColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${tournament.duration}${localizations.translate('hours')}',
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
                          height: 1.2,
                        ),
                        maxLines: 2,
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
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  carpFishing,
  casting,
}