import 'package:flutter/material.dart';
import '../../models/marker_map_model.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../localization/app_localizations.dart';

enum WaterBodySortType { alphabetical, byDate, byCount }

class WaterBodyData {
  final String name;
  final int mapsCount;
  final DateTime lastMapDate;

  WaterBodyData({
    required this.name,
    required this.mapsCount,
    required this.lastMapDate,
  });
}

class WaterBodyFilterScreen extends StatefulWidget {
  final List<MarkerMapModel> allMaps;
  final String? currentFilter;

  const WaterBodyFilterScreen({
    super.key,
    required this.allMaps,
    this.currentFilter,
  });

  @override
  State<WaterBodyFilterScreen> createState() => _WaterBodyFilterScreenState();
}

class _WaterBodyFilterScreenState extends State<WaterBodyFilterScreen> {
  final _searchController = TextEditingController();
  List<WaterBodyData> _allWaterBodies = [];
  List<WaterBodyData> _filteredWaterBodies = [];
  WaterBodySortType _sortType = WaterBodySortType.alphabetical;

  @override
  void initState() {
    super.initState();
    _prepareWaterBodiesData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _prepareWaterBodiesData() {
    final waterBodyMap = <String, List<MarkerMapModel>>{};

    // Группируем карты по названиям (водоемам)
    for (final map in widget.allMaps) {
      if (!waterBodyMap.containsKey(map.name)) {
        waterBodyMap[map.name] = [];
      }
      waterBodyMap[map.name]!.add(map);
    }

    // Создаем данные для каждого водоема
    _allWaterBodies = waterBodyMap.entries.map((entry) {
      final maps = entry.value;
      maps.sort((a, b) => b.date.compareTo(a.date)); // Сортируем по дате

      return WaterBodyData(
        name: entry.key,
        mapsCount: maps.length,
        lastMapDate: maps.first.date, // Последняя (самая новая) дата
      );
    }).toList();

    _applySortAndFilter();
  }

  void _onSearchChanged() {
    _applySortAndFilter();
  }

  void _applySortAndFilter() {
    // Фильтрация по поиску
    List<WaterBodyData> filtered = _allWaterBodies;

    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = _allWaterBodies.where((waterBody) {
        return waterBody.name.toLowerCase().contains(searchText);
      }).toList();
    }

    // Сортировка
    switch (_sortType) {
      case WaterBodySortType.alphabetical:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case WaterBodySortType.byDate:
        filtered.sort((a, b) => b.lastMapDate.compareTo(a.lastMapDate));
        break;
      case WaterBodySortType.byCount:
        filtered.sort((a, b) => b.mapsCount.compareTo(a.mapsCount));
        break;
    }

    setState(() {
      _filteredWaterBodies = filtered;
    });
  }

  void _changeSortType() {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('sort_by'),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption(
                  WaterBodySortType.alphabetical,
                  localizations.translate('alphabetically'),
                  Icons.sort_by_alpha,
                ),
                _buildSortOption(
                  WaterBodySortType.byDate,
                  localizations.translate('by_last_update'),
                  Icons.access_time,
                ),
                _buildSortOption(
                  WaterBodySortType.byCount,
                  localizations.translate('by_maps_count'),
                  Icons.format_list_numbered,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(WaterBodySortType sortType, String title, IconData icon) {
    final isSelected = _sortType == sortType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppConstants.primaryColor : AppConstants.textColor.withOpacity(0.6),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppConstants.primaryColor)
          : null,
      onTap: () {
        setState(() {
          _sortType = sortType;
        });
        _applySortAndFilter();
        Navigator.pop(context);
      },
    );
  }

  String _getSortTypeText(AppLocalizations localizations) {
    switch (_sortType) {
      case WaterBodySortType.alphabetical:
        return localizations.translate('alphabetically');
      case WaterBodySortType.byDate:
        return localizations.translate('by_last_update');
      case WaterBodySortType.byCount:
        return localizations.translate('by_maps_count');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('select_water_body'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: isSmallScreen ? 24 : 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Кнопка сортировки
          IconButton(
            icon: Icon(
              Icons.sort,
              color: AppConstants.textColor,
              size: isSmallScreen ? 24 : 28,
            ),
            onPressed: _changeSortType,
            tooltip: localizations.translate('sort'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppConstants.textColor),
              decoration: InputDecoration(
                hintText: localizations.translate('search_water_bodies'),
                hintStyle: TextStyle(color: AppConstants.textColor.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppConstants.textColor.withOpacity(0.6),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppConstants.textColor.withOpacity(0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: AppConstants.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Информация о сортировке и количестве
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${localizations.translate('found')}: ${_filteredWaterBodies.length}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${localizations.translate('sorted')}: ${_getSortTypeText(localizations)}',
                    style: TextStyle(
                      color: AppConstants.textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // Опция "Показать все"
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: widget.currentFilter == null
                  ? AppConstants.primaryColor.withOpacity(0.1)
                  : AppConstants.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: widget.currentFilter == null
                    ? BorderSide(color: AppConstants.primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                title: Text(
                  localizations.translate('show_all_maps'),
                  style: TextStyle(
                    color: widget.currentFilter == null
                        ? AppConstants.primaryColor
                        : AppConstants.textColor,
                    fontWeight: widget.currentFilter == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.currentFilter == null
                        ? AppConstants.primaryColor.withOpacity(0.2)
                        : AppConstants.textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.allMaps.length}',
                    style: TextStyle(
                      color: widget.currentFilter == null
                          ? AppConstants.primaryColor
                          : AppConstants.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context, null); // Возвращаем null = показать все
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Список водоемов
          Expanded(
            child: _filteredWaterBodies.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredWaterBodies.length,
              itemBuilder: (context, index) {
                final waterBody = _filteredWaterBodies[index];
                return _buildWaterBodyCard(waterBody);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: AppConstants.textColor.withOpacity(0.5),
              size: isSmallScreen ? 32 : 40,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.translate('no_water_bodies_found'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              localizations.translate('try_different_search'),
              style: TextStyle(
                color: AppConstants.textColor.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterBodyCard(WaterBodyData waterBody) {
    final isSelected = widget.currentFilter == waterBody.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? AppConstants.primaryColor.withOpacity(0.1)
          : AppConstants.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppConstants.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          waterBody.name,
          style: TextStyle(
            color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor.withOpacity(0.2)
                : AppConstants.textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${waterBody.mapsCount}',
            style: TextStyle(
              color: isSelected ? AppConstants.primaryColor : AppConstants.textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context, waterBody.name);
        },
      ),
    );
  }
}