// Путь: lib/models/shop_model.dart

class ShopModel {
  final String id;
  final String name;
  final String description;
  final String website;
  final String logoUrl;
  final List<String> categories;
  final ShopSpecialization specialization;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final Map<String, String>? workingHours;
  final List<String> services;
  final bool hasDelivery;
  final bool hasOnlineStore;
  final String? promoCode;
  final ShopStatus status;

  ShopModel({
    required this.id,
    required this.name,
    required this.description,
    required this.website,
    required this.logoUrl,
    required this.categories,
    required this.specialization,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.workingHours,
    this.services = const [],
    this.hasDelivery = false,
    this.hasOnlineStore = false,
    this.promoCode,
    this.status = ShopStatus.regular,
  });

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'website': website,
      'logoUrl': logoUrl,
      'categories': categories,
      'specialization': specialization.toString(),
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'services': services,
      'hasDelivery': hasDelivery,
      'hasOnlineStore': hasOnlineStore,
      'promoCode': promoCode,
      'status': status.toString(),
    };
  }

  // Создание из JSON
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      website: json['website'] as String,
      logoUrl: json['logoUrl'] as String,
      categories: List<String>.from(json['categories']),
      specialization: _parseSpecialization(json['specialization'] as String),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      workingHours:
          json['workingHours'] != null
              ? Map<String, String>.from(json['workingHours'])
              : null,
      services: List<String>.from(json['services'] ?? []),
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      hasOnlineStore: json['hasOnlineStore'] as bool? ?? false,
      promoCode: json['promoCode'] as String?,
      status: _parseStatus(json['status'] as String),
    );
  }

  static ShopSpecialization _parseSpecialization(String specialization) {
    switch (specialization) {
      case 'ShopSpecialization.carpFishing':
        return ShopSpecialization.carpFishing;
      case 'ShopSpecialization.spinning':
        return ShopSpecialization.spinning;
      case 'ShopSpecialization.feeder':
        return ShopSpecialization.feeder;
      case 'ShopSpecialization.floatFishing':
        return ShopSpecialization.floatFishing;
      case 'ShopSpecialization.iceFishing':
        return ShopSpecialization.iceFishing;
      case 'ShopSpecialization.universal':
        return ShopSpecialization.universal;
      default:
        return ShopSpecialization.universal;
    }
  }

  static ShopStatus _parseStatus(String status) {
    switch (status) {
      case 'ShopStatus.regular':
        return ShopStatus.regular;
      case 'ShopStatus.recommended':
        return ShopStatus.recommended;
      case 'ShopStatus.premium':
        return ShopStatus.premium;
      default:
        return ShopStatus.regular;
    }
  }

  // Копирование с изменениями
  ShopModel copyWith({
    String? id,
    String? name,
    String? description,
    String? website,
    String? logoUrl,
    List<String>? categories,
    ShopSpecialization? specialization,
    String? phone,
    String? email,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    Map<String, String>? workingHours,
    List<String>? services,
    bool? hasDelivery,
    bool? hasOnlineStore,
    String? promoCode,
    ShopStatus? status,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workingHours: workingHours ?? this.workingHours,
      services: services ?? this.services,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      hasOnlineStore: hasOnlineStore ?? this.hasOnlineStore,
      promoCode: promoCode ?? this.promoCode,
      status: status ?? this.status,
    );
  }
}

// Специализации магазинов
enum ShopSpecialization {
  carpFishing, // Карповая рыбалка
  spinning, // Спиннинг
  feeder, // Фидер
  floatFishing, // Поплавочная рыбалка
  iceFishing, // Зимняя рыбалка
  universal, // Универсальный
}

extension ShopSpecializationExtension on ShopSpecialization {
  String get displayName {
    switch (this) {
      case ShopSpecialization.carpFishing:
        return 'Карповая рыбалка';
      case ShopSpecialization.spinning:
        return 'Спиннинг';
      case ShopSpecialization.feeder:
        return 'Фидер';
      case ShopSpecialization.floatFishing:
        return 'Поплавочная рыбалка';
      case ShopSpecialization.iceFishing:
        return 'Зимняя рыбалка';
      case ShopSpecialization.universal:
        return 'Универсальный';
    }
  }

  String get localizationKey {
    switch (this) {
      case ShopSpecialization.carpFishing:
        return 'carp_fishing_shop';
      case ShopSpecialization.spinning:
        return 'spinning_shop';
      case ShopSpecialization.feeder:
        return 'feeder_shop';
      case ShopSpecialization.floatFishing:
        return 'float_fishing_shop';
      case ShopSpecialization.iceFishing:
        return 'ice_fishing_shop';
      case ShopSpecialization.universal:
        return 'universal_shop';
    }
  }

  String get icon {
    switch (this) {
      case ShopSpecialization.carpFishing:
        return '🐟';
      case ShopSpecialization.spinning:
        return '🎣';
      case ShopSpecialization.feeder:
        return '🪝';
      case ShopSpecialization.floatFishing:
        return '🎈';
      case ShopSpecialization.iceFishing:
        return '❄️';
      case ShopSpecialization.universal:
        return '🏪';
    }
  }
}

// Статусы магазинов
enum ShopStatus {
  regular, // Обычный
  recommended, // Рекомендуемый
  premium, // Премиум
}

extension ShopStatusExtension on ShopStatus {
  String get displayName {
    switch (this) {
      case ShopStatus.regular:
        return 'Обычный';
      case ShopStatus.recommended:
        return 'Рекомендуемый';
      case ShopStatus.premium:
        return 'Премиум';
    }
  }

  String get localizationKey {
    switch (this) {
      case ShopStatus.regular:
        return 'regular_shop';
      case ShopStatus.recommended:
        return 'recommended_shop';
      case ShopStatus.premium:
        return 'premium_shop';
    }
  }
}
