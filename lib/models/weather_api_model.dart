// Путь: lib/models/weather_api_model.dart

class WeatherApiResponse {
  final Location location;
  final CurrentWeather current;
  final List<ForecastDay> forecast;

  WeatherApiResponse({
    required this.location,
    required this.current,
    required this.forecast,
  });

  factory WeatherApiResponse.fromJson(Map<String, dynamic> json) {
    return WeatherApiResponse(
      location: Location.fromJson(json['location']),
      current: CurrentWeather.fromJson(json['current']),
      forecast: json['forecast'] != null
          ? List<ForecastDay>.from(
          json['forecast']['forecastday']?.map((x) => ForecastDay.fromJson(x)) ?? []
      )
          : [],
    );
  }
}

class Location {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String localtime;

  Location({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.localtime,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      country: json['country'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      localtime: json['localtime'] ?? '',
    );
  }
}

class CurrentWeather {
  final double tempC;
  final double tempF;
  final int isDay;
  final WeatherCondition condition;
  final double windKph;
  final double windMph;
  final int windDegree;
  final String windDir;
  final double pressureMb;
  final double pressureIn;
  final double precipMm;
  final double precipIn;
  final int humidity;
  final int cloud;
  final double feelslikeC;
  final double feelslikeF;
  final double visKm;
  final double visMiles;
  final double uv;
  final double gustKph;
  final double gustMph;

  CurrentWeather({
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.condition,
    required this.windKph,
    required this.windMph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.precipMm,
    required this.precipIn,
    required this.humidity,
    required this.cloud,
    required this.feelslikeC,
    required this.feelslikeF,
    required this.visKm,
    required this.visMiles,
    required this.uv,
    required this.gustKph,
    required this.gustMph,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      tempC: (json['temp_c'] ?? 0.0).toDouble(),
      tempF: (json['temp_f'] ?? 0.0).toDouble(),
      isDay: json['is_day'] ?? 1,
      condition: WeatherCondition.fromJson(json['condition'] ?? {}),
      windKph: (json['wind_kph'] ?? 0.0).toDouble(),
      windMph: (json['wind_mph'] ?? 0.0).toDouble(),
      windDegree: json['wind_degree'] ?? 0,
      windDir: json['wind_dir'] ?? '',
      pressureMb: (json['pressure_mb'] ?? 0.0).toDouble(),
      pressureIn: (json['pressure_in'] ?? 0.0).toDouble(),
      precipMm: (json['precip_mm'] ?? 0.0).toDouble(),
      precipIn: (json['precip_in'] ?? 0.0).toDouble(),
      humidity: json['humidity'] ?? 0,
      cloud: json['cloud'] ?? 0,
      feelslikeC: (json['feelslike_c'] ?? 0.0).toDouble(),
      feelslikeF: (json['feelslike_f'] ?? 0.0).toDouble(),
      visKm: (json['vis_km'] ?? 0.0).toDouble(),
      visMiles: (json['vis_miles'] ?? 0.0).toDouble(),
      uv: (json['uv'] ?? 0.0).toDouble(),
      gustKph: (json['gust_kph'] ?? 0.0).toDouble(),
      gustMph: (json['gust_mph'] ?? 0.0).toDouble(),
    );
  }
}

class WeatherCondition {
  final String text;
  final String icon;
  final int code;

  WeatherCondition({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      text: json['text'] ?? '',
      icon: json['icon'] ?? '',
      code: json['code'] ?? 0,
    );
  }
}

class ForecastDay {
  final String date;
  final DayWeather day;
  final Astro astro;
  final List<HourWeather> hour;

  ForecastDay({
    required this.date,
    required this.day,
    required this.astro,
    required this.hour,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'] ?? '',
      day: DayWeather.fromJson(json['day'] ?? {}),
      astro: Astro.fromJson(json['astro'] ?? {}),
      hour: json['hour'] != null
          ? List<HourWeather>.from(
          json['hour'].map((x) => HourWeather.fromJson(x))
      )
          : [],
    );
  }
}

class DayWeather {
  final double maxtempC;
  final double maxtempF;
  final double mintempC;
  final double mintempF;
  final double avgtempC;
  final double avgtempF;
  final double maxwindKph;
  final double maxwindMph;
  final double totalprecipMm;
  final double totalprecipIn;
  final int avghumidity;
  final int dailyWillItRain;
  final int dailyChanceOfRain;
  final int dailyWillItSnow;
  final int dailyChanceOfSnow;
  final WeatherCondition condition;
  final double uv;

  DayWeather({
    required this.maxtempC,
    required this.maxtempF,
    required this.mintempC,
    required this.mintempF,
    required this.avgtempC,
    required this.avgtempF,
    required this.maxwindKph,
    required this.maxwindMph,
    required this.totalprecipMm,
    required this.totalprecipIn,
    required this.avghumidity,
    required this.dailyWillItRain,
    required this.dailyChanceOfRain,
    required this.dailyWillItSnow,
    required this.dailyChanceOfSnow,
    required this.condition,
    required this.uv,
  });

  factory DayWeather.fromJson(Map<String, dynamic> json) {
    return DayWeather(
      maxtempC: (json['maxtemp_c'] ?? 0.0).toDouble(),
      maxtempF: (json['maxtemp_f'] ?? 0.0).toDouble(),
      mintempC: (json['mintemp_c'] ?? 0.0).toDouble(),
      mintempF: (json['mintemp_f'] ?? 0.0).toDouble(),
      avgtempC: (json['avgtemp_c'] ?? 0.0).toDouble(),
      avgtempF: (json['avgtemp_f'] ?? 0.0).toDouble(),
      maxwindKph: (json['maxwind_kph'] ?? 0.0).toDouble(),
      maxwindMph: (json['maxwind_mph'] ?? 0.0).toDouble(),
      totalprecipMm: (json['totalprecip_mm'] ?? 0.0).toDouble(),
      totalprecipIn: (json['totalprecip_in'] ?? 0.0).toDouble(),
      avghumidity: json['avghumidity'] ?? 0,
      dailyWillItRain: json['daily_will_it_rain'] ?? 0,
      dailyChanceOfRain: json['daily_chance_of_rain'] ?? 0,
      dailyWillItSnow: json['daily_will_it_snow'] ?? 0,
      dailyChanceOfSnow: json['daily_chance_of_snow'] ?? 0,
      condition: WeatherCondition.fromJson(json['condition'] ?? {}),
      uv: (json['uv'] ?? 0.0).toDouble(),
    );
  }
}

class Astro {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final String moonIllumination;

  Astro({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
  });

  factory Astro.fromJson(Map<String, dynamic> json) {
    return Astro(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      moonrise: json['moonrise'] ?? '',
      moonset: json['moonset'] ?? '',
      moonPhase: json['moon_phase'] ?? '',
      moonIllumination: json['moon_illumination'] ?? '',
    );
  }
}

class HourWeather {
  final String time;
  final double tempC;
  final double tempF;
  final int isDay;
  final WeatherCondition condition;
  final double windKph;
  final double windMph;
  final int windDegree;
  final String windDir;
  final double pressureMb;
  final double pressureIn;
  final double precipMm;
  final double precipIn;
  final int humidity;
  final int cloud;
  final double feelslikeC;
  final double feelslikeF;
  final double windchillC;
  final double windchillF;
  final double heatindexC;
  final double heatindexF;
  final double dewpointC;
  final double dewpointF;
  final int willItRain;
  final int chanceOfRain;
  final int willItSnow;
  final int chanceOfSnow;
  final double visKm;
  final double visMiles;
  final double gustKph;
  final double gustMph;
  final double uv;

  HourWeather({
    required this.time,
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.condition,
    required this.windKph,
    required this.windMph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.precipMm,
    required this.precipIn,
    required this.humidity,
    required this.cloud,
    required this.feelslikeC,
    required this.feelslikeF,
    required this.windchillC,
    required this.windchillF,
    required this.heatindexC,
    required this.heatindexF,
    required this.dewpointC,
    required this.dewpointF,
    required this.willItRain,
    required this.chanceOfRain,
    required this.willItSnow,
    required this.chanceOfSnow,
    required this.visKm,
    required this.visMiles,
    required this.gustKph,
    required this.gustMph,
    required this.uv,
  });

  factory HourWeather.fromJson(Map<String, dynamic> json) {
    return HourWeather(
      time: json['time'] ?? '',
      tempC: (json['temp_c'] ?? 0.0).toDouble(),
      tempF: (json['temp_f'] ?? 0.0).toDouble(),
      isDay: json['is_day'] ?? 1,
      condition: WeatherCondition.fromJson(json['condition'] ?? {}),
      windKph: (json['wind_kph'] ?? 0.0).toDouble(),
      windMph: (json['wind_mph'] ?? 0.0).toDouble(),
      windDegree: json['wind_degree'] ?? 0,
      windDir: json['wind_dir'] ?? '',
      pressureMb: (json['pressure_mb'] ?? 0.0).toDouble(),
      pressureIn: (json['pressure_in'] ?? 0.0).toDouble(),
      precipMm: (json['precip_mm'] ?? 0.0).toDouble(),
      precipIn: (json['precip_in'] ?? 0.0).toDouble(),
      humidity: json['humidity'] ?? 0,
      cloud: json['cloud'] ?? 0,
      feelslikeC: (json['feelslike_c'] ?? 0.0).toDouble(),
      feelslikeF: (json['feelslike_f'] ?? 0.0).toDouble(),
      windchillC: (json['windchill_c'] ?? 0.0).toDouble(),
      windchillF: (json['windchill_f'] ?? 0.0).toDouble(),
      heatindexC: (json['heatindex_c'] ?? 0.0).toDouble(),
      heatindexF: (json['heatindex_f'] ?? 0.0).toDouble(),
      dewpointC: (json['dewpoint_c'] ?? 0.0).toDouble(),
      dewpointF: (json['dewpoint_f'] ?? 0.0).toDouble(),
      willItRain: json['will_it_rain'] ?? 0,
      chanceOfRain: json['chance_of_rain'] ?? 0,
      willItSnow: json['will_it_snow'] ?? 0,
      chanceOfSnow: json['chance_of_snow'] ?? 0,
      visKm: (json['vis_km'] ?? 0.0).toDouble(),
      visMiles: (json['vis_miles'] ?? 0.0).toDouble(),
      gustKph: (json['gust_kph'] ?? 0.0).toDouble(),
      gustMph: (json['gust_mph'] ?? 0.0).toDouble(),
      uv: (json['uv'] ?? 0.0).toDouble(),
    );
  }
}