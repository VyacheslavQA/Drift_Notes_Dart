// Путь: lib/models/fishing_note_model.dart

class FishingNoteModel {
  final String id;
  final String userId;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime date;
  final DateTime? endDate;
  final bool isMultiDay;
  final String tackle;
  final String notes;
  final List<String> photoUrls;
  final String fishingType;
  final FishingWeather? weather;
  final List<BiteRecord> biteRecords;
  final Map<String, List<String>> dayBiteMaps;
  final List<String> fishingSpots;
  final List<Map<String, dynamic>> mapMarkers;
  final String coverPhotoUrl;
  final Map<String, dynamic>? coverCropSettings;
  final String title;

  FishingNoteModel({
    required this.id,
    required this.userId,
    required this.location,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.date,
    this.endDate,
    this.isMultiDay = false,
    this.tackle = '',
    this.notes = '',
    this.photoUrls = const [],
    this.fishingType = '',
    this.weather,
    this.biteRecords = const [],
    this.dayBiteMaps = const {},
    this.fishingSpots = const ['Основная точка'],
    this.mapMarkers = const [],
    this.coverPhotoUrl = '',
    this.coverCropSettings,
    this.title = '',
  });

  factory FishingNoteModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FishingNoteModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      date: (json['date'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['date'])
          : DateTime.now(),
      endDate: (json['endDate'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      isMultiDay: json['isMultiDay'] ?? false,
      tackle: json['tackle'] ?? '',
      notes: json['notes'] ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      fishingType: json['fishingType'] ?? '',
      weather: json['weather'] != null
          ? FishingWeather.fromJson(json['weather'])
          : null,
      biteRecords: (json['biteRecords'] != null)
          ? List<BiteRecord>.from(
          json['biteRecords'].map((x) => BiteRecord.fromJson(x)))
          : [],
      dayBiteMaps: (json['dayBiteMaps'] != null)
          ? Map<String, List<String>>.from(json['dayBiteMaps'].map(
              (key, value) => MapEntry(key, List<String>.from(value))))
          : {},
      fishingSpots: List<String>.from(json['fishingSpots'] ?? ['Основная точка']),
      mapMarkers: (json['mapMarkers'] != null)
          ? List<Map<String, dynamic>>.from(json['mapMarkers'])
          : [],
      coverPhotoUrl: json['coverPhotoUrl'] ?? '',
      coverCropSettings: json['coverCropSettings'],
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': date.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isMultiDay': isMultiDay,
      'tackle': tackle,
      'notes': notes,
      'photoUrls': photoUrls,
      'fishingType': fishingType,
      'weather': weather?.toJson(),
      'biteRecords': biteRecords.map((x) => x.toJson()).toList(),
      'dayBiteMaps': dayBiteMaps,
      'fishingSpots': fishingSpots,
      'mapMarkers': mapMarkers,
      'coverPhotoUrl': coverPhotoUrl,
      'coverCropSettings': coverCropSettings,
      'title': title,
    };
  }

  FishingNoteModel copyWith({
    String? id,
    String? userId,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? date,
    DateTime? endDate,
    bool? isMultiDay,
    String? tackle,
    String? notes,
    List<String>? photoUrls,
    String? fishingType,
    FishingWeather? weather,
    List<BiteRecord>? biteRecords,
    Map<String, List<String>>? dayBiteMaps,
    List<String>? fishingSpots,
    List<Map<String, dynamic>>? mapMarkers,
    String? coverPhotoUrl,
    Map<String, dynamic>? coverCropSettings,
    String? title,
  }) {
    return FishingNoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      isMultiDay: isMultiDay ?? this.isMultiDay,
      tackle: tackle ?? this.tackle,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      fishingType: fishingType ?? this.fishingType,
      weather: weather ?? this.weather,
      biteRecords: biteRecords ?? this.biteRecords,
      dayBiteMaps: dayBiteMaps ?? this.dayBiteMaps,
      fishingSpots: fishingSpots ?? this.fishingSpots,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      coverCropSettings: coverCropSettings ?? this.coverCropSettings,
      title: title ?? this.title,
    );
  }

  // Получение самой крупной рыбы
  BiteRecord? get biggestFish {
    if (biteRecords.isEmpty) return null;

    BiteRecord biggest = biteRecords.first;
    for (var record in biteRecords) {
      if (record.weight > biggest.weight) {
        biggest = record;
      }
    }

    // Если нет рыбы с весом > 0, вернем null
    return biggest.weight > 0 ? biggest : null;
  }
}

class FishingWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final String windDirection;
  final String weatherDescription;
  final int cloudCover;
  final String moonPhase;
  final DateTime observationTime;
  final String sunrise;
  final String sunset;
  final bool isDay;

  FishingWeather({
    this.temperature = 0.0,
    this.feelsLike = 0.0,
    this.humidity = 0,
    this.pressure = 0.0,
    this.windSpeed = 0.0,
    this.windDirection = '',
    this.weatherDescription = '',
    this.cloudCover = 0,
    this.moonPhase = '',
    required this.observationTime,
    this.sunrise = '',
    this.sunset = '',
    this.isDay = true,
  });

  factory FishingWeather.fromJson(Map<String, dynamic> json) {
    return FishingWeather(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 0.0,
      humidity: json['humidity'] ?? 0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      windDirection: json['windDirection'] ?? '',
      weatherDescription: json['weatherDescription'] ?? '',
      cloudCover: json['cloudCover'] ?? 0,
      moonPhase: json['moonPhase'] ?? '',
      observationTime: (json['observationTime'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['observationTime'])
          : DateTime.now(),
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      isDay: json['isDay'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'weatherDescription': weatherDescription,
      'cloudCover': cloudCover,
      'moonPhase': moonPhase,
      'observationTime': observationTime.millisecondsSinceEpoch,
      'sunrise': sunrise,
      'sunset': sunset,
      'isDay': isDay,
    };
  }
}

class BiteRecord {
  final String id;
  final DateTime time;
  final String fishType;
  final double weight;
  final double length;
  final String notes;
  final int dayIndex;
  final int spotIndex;
  final List<String> photoUrls;

  BiteRecord({
    required this.id,
    required this.time,
    this.fishType = '',
    this.weight = 0.0,
    this.length = 0.0,
    this.notes = '',
    this.dayIndex = 0,
    this.spotIndex = 0,
    this.photoUrls = const [],
  });

  factory BiteRecord.fromJson(Map<String, dynamic> json) {
    return BiteRecord(
      id: json['id'] ?? '',
      time: (json['time'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(json['time'])
          : DateTime.now(),
      fishType: json['fishType'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      dayIndex: json['dayIndex'] ?? 0,
      spotIndex: json['spotIndex'] ?? 0,
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.millisecondsSinceEpoch,
      'fishType': fishType,
      'weight': weight,
      'length': length,
      'notes': notes,
      'dayIndex': dayIndex,
      'spotIndex': spotIndex,
      'photoUrls': photoUrls,
    };
  }

  BiteRecord copyWith({
    String? id,
    DateTime? time,
    String? fishType,
    double? weight,
    double? length,
    String? notes,
    int? dayIndex,
    int? spotIndex,
    List<String>? photoUrls,
  }) {
    return BiteRecord(
      id: id ?? this.id,
      time: time ?? this.time,
      fishType: fishType ?? this.fishType,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      notes: notes ?? this.notes,
      dayIndex: dayIndex ?? this.dayIndex,
      spotIndex: spotIndex ?? this.spotIndex,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }
}