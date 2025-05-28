// Путь: lib/services/shop_service.dart

import '../models/shop_model.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  factory ShopService() => _instance;
  ShopService._internal();

  // Статический список магазинов (в будущем можно заменить на API)
  List<ShopModel> getAllShops() {
    return [
      // MasterCarp - первый магазин
      ShopModel(
        id: 'mastercarp_1',
        name: 'MasterCarp',
        description: 'Специализированный магазин товаров для карповой рыбалки. Широкий ассортимент снастей, прикормок и аксессуаров для успешной карповой ловли.',
        website: 'https://master-carp.kz',
        logoUrl: 'assets/images/shops/mastercarp_logo.png', // Здесь будет ваш логотип
        categories: [
          'Карповые удилища',
          'Катушки для карпа',
          'Прикормки и бойлы',
          'Сигнализаторы поклевки',
          'Подставки и род-поды',
          'Аксессуары для карпфишинга',
          'Садки и мешки',
          'Снасти и оснастки',
        ],
        specialization: ShopSpecialization.carpFishing,
        services: [
          'Консультации по снастям',
          'Подбор комплектов',
          'Советы по технике ловли',
        ],
        hasDelivery: true,
        hasOnlineStore: true,
        status: ShopStatus.recommended,
        // Контактные данные можно добавить позже
        // phone: '+7 (XXX) XXX-XX-XX',
        // email: 'info@master-carp.kz',
        // city: 'Алматы',
      ),

      // Можно добавить еще магазины в будущем
      // ShopModel(
      //   id: 'fishing_world_1',
      //   name: 'Мир Рыбалки',
      //   description: 'Универсальный магазин рыболовных товаров',
      //   website: 'https://example.com',
      //   logoUrl: 'assets/images/shops/fishing_world_logo.png',
      //   categories: ['Спиннинги', 'Катушки', 'Приманки'],
      //   specialization: ShopSpecialization.universal,
      //   hasDelivery: true,
      //   hasOnlineStore: true,
      //   status: ShopStatus.regular,
      // ),
    ];
  }

  // Получить магазин по ID
  ShopModel? getShopById(String id) {
    try {
      return getAllShops().firstWhere((shop) => shop.id == id);
    } catch (e) {
      return null;
    }
  }

  // Поиск магазинов по названию
  List<ShopModel> searchShops(String query) {
    if (query.isEmpty) return getAllShops();

    final lowercaseQuery = query.toLowerCase();
    return getAllShops().where((shop) =>
    shop.name.toLowerCase().contains(lowercaseQuery) ||
        shop.description.toLowerCase().contains(lowercaseQuery) ||
        shop.categories.any((category) =>
            category.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  // Фильтрация по специализации
  List<ShopModel> getShopsBySpecialization(ShopSpecialization specialization) {
    return getAllShops().where((shop) =>
    shop.specialization == specialization
    ).toList();
  }

  // Получить рекомендуемые магазины
  List<ShopModel> getRecommendedShops() {
    return getAllShops().where((shop) =>
    shop.status == ShopStatus.recommended ||
        shop.status == ShopStatus.premium
    ).toList();
  }

  // Получить магазины с доставкой
  List<ShopModel> getShopsWithDelivery() {
    return getAllShops().where((shop) => shop.hasDelivery).toList();
  }

  // Получить онлайн-магазины
  List<ShopModel> getOnlineShops() {
    return getAllShops().where((shop) => shop.hasOnlineStore).toList();
  }

  // Получить статистику по специализациям
  Map<ShopSpecialization, int> getSpecializationStats() {
    final stats = <ShopSpecialization, int>{};
    final shops = getAllShops();

    for (final shop in shops) {
      stats[shop.specialization] = (stats[shop.specialization] ?? 0) + 1;
    }

    return stats;
  }

  // Получить все уникальные категории товаров
  List<String> getAllCategories() {
    final categories = <String>{};

    for (final shop in getAllShops()) {
      categories.addAll(shop.categories);
    }

    return categories.toList()..sort();
  }

  // Получить магазины по категории товаров
  List<ShopModel> getShopsByCategory(String category) {
    return getAllShops().where((shop) =>
        shop.categories.any((shopCategory) =>
            shopCategory.toLowerCase().contains(category.toLowerCase())
        )
    ).toList();
  }
}