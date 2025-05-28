// Путь: lib/screens/shops/shops_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../localization/app_localizations.dart';
import 'shop_detail_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> with TickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final TextEditingController _searchController = TextEditingController();

  List<ShopModel> _allShops = [];
  List<ShopModel> _filteredShops = [];
  String _searchQuery = '';
  ShopSpecialization? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadShops() {
    setState(() {
      _allShops = _shopService.getAllShops();
      _filteredShops = _allShops;
    });
  }

  void _applyFilters() {
    List<ShopModel> filtered = _allShops;

    // Применяем поиск
    if (_searchQuery.isNotEmpty) {
      filtered = _shopService.searchShops(_searchQuery);
    } else {
      filtered = _allShops;
    }

    // Применяем фильтр по специализации
    if (_selectedSpecialization != null) {
      filtered = filtered.where((shop) =>
      shop.specialization == _selectedSpecialization
      ).toList();
    }

    setState(() {
      _filteredShops = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onSpecializationFilterChanged(ShopSpecialization? specialization) {
    setState(() {
      _selectedSpecialization = specialization;
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
          localizations.translate('shops'),
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
                hintText: localizations.translate('search_shops'),
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

          // Фильтры по специализации
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Все магазины
                _buildFilterChip(
                  label: localizations.translate('all_shops'),
                  isSelected: _selectedSpecialization == null,
                  onTap: () => _onSpecializationFilterChanged(null),
                ),

                const SizedBox(width: 8),

                // Фильтры по специализациям
                ...ShopSpecialization.values.map((spec) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: spec.displayName,
                        icon: spec.icon,
                        isSelected: _selectedSpecialization == spec,
                        onTap: () => _onSpecializationFilterChanged(spec),
                      ),
                    ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                  localizations.translate('total_shops'),
                  _allShops.length.toString(),
                  Icons.store,
                ),
                _buildStatItem(
                  localizations.translate('with_delivery'),
                  _shopService.getShopsWithDelivery().length.toString(),
                  Icons.local_shipping,
                ),
                _buildStatItem(
                  localizations.translate('online_stores'),
                  _shopService.getOnlineShops().length.toString(),
                  Icons.shopping_cart,
                ),
                _buildStatItem(
                  localizations.translate('recommended'),
                  _shopService.getRecommendedShops().length.toString(),
                  Icons.star,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Список магазинов
          Expanded(
            child: _buildShopsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.textColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildShopsList() {
    final localizations = AppLocalizations.of(context);

    if (_filteredShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: AppConstants.textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? localizations.translate('no_shops_found')
                  : localizations.translate('no_shops_available'),
              style: TextStyle(
                color: AppConstants.textColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        final shop = _filteredShops[index];
        return _buildShopCard(shop);
      },
    );
  }

  Widget _buildShopCard(ShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopDetailScreen(shop: shop),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Логотип магазина (placeholder пока)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/shops/mastercarp_logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            shop.specialization.icon,
                            style: const TextStyle(fontSize: 28),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Информация о магазине
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название и статус
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (shop.status != ShopStatus.regular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: shop.status == ShopStatus.premium
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                shop.status.displayName,
                                style: TextStyle(
                                  color: shop.status == ShopStatus.premium
                                      ? Colors.amber
                                      : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Специализация
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shop.specialization.displayName,
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Описание
                      Text(
                        shop.description,
                        style: TextStyle(
                          color: AppConstants.textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Особенности
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (shop.hasOnlineStore)
                            _buildFeatureChip(
                              Icons.shopping_cart,
                              'Интернет-магазин',
                            ),
                          if (shop.hasDelivery)
                            _buildFeatureChip(
                              Icons.local_shipping,
                              'Доставка',
                            ),
                          if (shop.services.isNotEmpty)
                            _buildFeatureChip(
                              Icons.build,
                              'Услуги',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Стрелка
                Icon(
                  Icons.chevron_right,
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppConstants.textColor.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}