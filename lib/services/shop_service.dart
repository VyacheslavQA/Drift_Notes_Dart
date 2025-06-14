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
        description: 'mastercarp_description', // вместо полного текста
        website: 'https://master-carp.kz',
        logoUrl: 'assets/shops/mastercarp_logo.png',
        categories: [], // Убираем категории
        specialization: ShopSpecialization.carpFishing,
        phone: '+7(777)162-10-01',
        email: 'info@master-carp.kz',
        address:
            'г. Алматы, ул.Сатпаева 145а/2, заезд с Абая, территория "Car Service" 2 этаж',
        city: 'Алматы',
        workingHours: {
          'monday': 'Пн-Вс 10.00 - 20.00',
          'tuesday': 'Пн-Вс 10.00 - 20.00',
          'wednesday': 'Пн-Вс 10.00 - 20.00',
          'thursday': 'Пн-Вс 10.00 - 20.00',
          'friday': 'Пн-Вс 10.00 - 20.00',
          'saturday': 'Пн-Вс 10.00 - 20.00',
          'sunday': 'Пн-Вс 10.00 - 20.00',
        },
        services: [
          'consultation_on_tackle',
          'kit_selection',
          'fishing_technique_advice',
        ],
        hasDelivery: true,
        hasOnlineStore: true,
        status: ShopStatus.recommended,
      ),

      // Можно добавить еще магазины в будущем
      // ShopModel(
      //   id: 'fishing_world_1',
      //   name: 'Мир Рыбалки',
      //   description: 'universal_fishing_store',
      //   website: 'https://example.com',
      //   logoUrl: 'assets/images/shops/fishing_world_logo.png',
      //   categories: ['spinning_rods', 'reels', 'lures'],
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
    return getAllShops()
        .where(
          (shop) =>
              shop.name.toLowerCase().contains(lowercaseQuery) ||
              shop.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  // Фильтрация по специализации
  List<ShopModel> getShopsBySpecialization(ShopSpecialization specialization) {
    return getAllShops()
        .where((shop) => shop.specialization == specialization)
        .toList();
  }

  // Получить рекомендуемые магазины
  List<ShopModel> getRecommendedShops() {
    return getAllShops()
        .where(
          (shop) =>
              shop.status == ShopStatus.recommended ||
              shop.status == ShopStatus.premium,
        )
        .toList();
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

  // Получить все уникальные категории товаров (теперь возвращаем ключи локализации)
  List<String> getAllCategories() {
    final categories = <String>{};

    for (final shop in getAllShops()) {
      categories.addAll(shop.categories);
    }

    return categories.toList()..sort();
  }

  // Получить магазины по категории товаров (поиск по ключам локализации)
  List<ShopModel> getShopsByCategory(String categoryKey) {
    return getAllShops()
        .where((shop) => shop.categories.contains(categoryKey))
        .toList();
  }
}
