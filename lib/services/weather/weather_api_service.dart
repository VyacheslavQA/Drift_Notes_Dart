// Путь: lib/models/weather_api_model.dart

class WeatherApiResponse {
  final Location location;
  final Current current;
  final List<ForecastDay> forecast;

  WeatherApiResponse({
    required this.location,
    required this.current,
    required this.forecast,
  });

  factory WeatherApiResponse.fromJson(Map<String, dynamic> json) {
    return WeatherApiResponse(
      location: Location.fromJson(json['location'] ?? {}),
      current: Current.fromJson(json['current'] ?? {}),
      forecast: (json['forecast']?['forecastday'] as List<dynamic>?)
          ?.map((item) => ForecastDay.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'current': current.toJson(),
      'forecast': {
        'forecastday': forecast.map((day) => day.toJson()).toList(),
      },
    };
  }
}

class Location {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String tzId;

  Location({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tzId,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      tzId: json['tz_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'region': region,
      'country': country,
      'lat': lat,
      'lon': lon,
      'tz_id': tzId,
    };
  }
}

class Current {
  final double tempC;
  final double feelslikeC;
  final int humidity;
  final double pressureMb;
  final double windKph;
  final String windDir;
  final Condition condition;
  final int cloud;
  final int isDay;
  final double visKm;
  final double uv;

  Current({
    required this.tempC,
    required this.feelslikeC,
    required this.humidity,
    required this.pressureMb,
    required this.windKph,
    required this.windDir,
    required this.condition,
    required this.cloud,
    required this.isDay,
    required this.visKm,
    required this.uv,
  });

  factory Current.fromJson(Map<String, dynamic> json) {
    return Current(
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      feelslikeC: (json['feelslike_c'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      pressureMb: (json['pressure_mb'] as num?)?.toDouble() ?? 0.0,
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windDir: json['wind_dir']?.toString() ?? '',
      condition: Condition.fromJson(json['condition'] ?? {}),
      cloud: (json['cloud'] as num?)?.toInt() ?? 0,
      isDay: (json['is_day'] as num?)?.toInt() ?? 0,
      visKm: (json['vis_km'] as num?)?.toDouble() ?? 0.0,
      uv: (json['uv'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp_c': tempC,
      'feelslike_c': feelslikeC,
      'humidity': humidity,
      'pressure_mb': pressureMb,
      'wind_kph': windKph,
      'wind_dir': windDir,
      'condition': condition.toJson(),
      'cloud': cloud,
      'is_day': isDay,
      'vis_km': visKm,
      'uv': uv,
    };
  }
}

class Condition {
  final String text;
  final String icon;
  final int code;

  Condition({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      text: json['text']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      code: (json['code'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'icon': icon,
      'code': code,
    };
  }
}

class ForecastDay {
  final String date;
  final Day day;
  final Astro astro;
  final List<Hour> hour;

  ForecastDay({
    required this.date,
    required this.day,
    required this.astro,
    required this.hour,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date']?.toString() ?? '',
      day: Day.fromJson(json['day'] ?? {}),
      astro: Astro.fromJson(json['astro'] ?? {}),
      hour: (json['hour'] as List<dynamic>?)
          ?.map((item) => Hour.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day': day.toJson(),
      'astro': astro.toJson(),
      'hour': hour.map((h) => h.toJson()).toList(),
    };
  }
}

class Day {
  final double maxtempC;
  final double mintempC;
  final Condition condition;

  Day({
    required this.maxtempC,
    required this.mintempC,
    required this.condition,
  });

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      maxtempC: (json['maxtemp_c'] as num?)?.toDouble() ?? 0.0,
      mintempC: (json['mintemp_c'] as num?)?.toDouble() ?? 0.0,
      condition: Condition.fromJson(json['condition'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxtemp_c': maxtempC,
      'mintemp_c': mintempC,
      'condition': condition.toJson(),
    };
  }
}

class Hour {
  final String time;
  final double tempC;
  final Condition condition;
  final double windKph;
  final String windDir;
  final int humidity;
  final double chanceOfRain;
  final double pressureMb;  // Добавляем поле давления

  Hour({
    required this.time,
    required this.tempC,
    required this.condition,
    required this.windKph,
    required this.windDir,
    required this.humidity,
    required this.chanceOfRain,
    required this.pressureMb,  // Добавляем в конструктор
  });

  factory Hour.fromJson(Map<String, dynamic> json) {
    return Hour(
      time: json['time']?.toString() ?? '',
      tempC: (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      condition: Condition.fromJson(json['condition'] ?? {}),
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 0.0,
      windDir: json['wind_dir']?.toString() ?? '',
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      chanceOfRain: (json['chance_of_rain'] as num?)?.toDouble() ?? 0.0,
      pressureMb: (json['pressure_mb'] as num?)?.toDouble() ?? 0.0,  // Добавляем парсинг
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temp_c': tempC,
      'condition': condition.toJson(),
      'wind_kph': windKph,
      'wind_dir': windDir,
      'humidity': humidity,
      'chance_of_rain': chanceOfRain,
      'pressure_mb': pressureMb,  // Добавляем в JSON
    };
  }
}

class Astro {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;

  Astro({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
  });

  factory Astro.fromJson(Map<String, dynamic> json) {
    return Astro(
      sunrise: json['sunrise']?.toString() ?? '',
      sunset: json['sunset']?.toString() ?? '',
      moonrise: json['moonrise']?.toString() ?? '',
      moonset: json['moonset']?.toString() ?? '',
      moonPhase: json['moon_phase']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'moon_phase': moonPhase,
    };
  }
}