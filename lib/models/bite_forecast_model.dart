// Путь: lib/models/bite_forecast_model.dart

class BiteForecastModel {
  final double overallActivity; // 0.0 - 1.0
  final int scorePoints; // 0 - 100
  final BiteForecastLevel level;
  final String recommendation;
  final List<String> tips;
  final Map<String, BiteFactor> factors;
  final List<OptimalTimeWindow> bestTimeWindows;
  final DateTime calculatedAt;

  BiteForecastModel({
    required this.overallActivity,
    required this.scorePoints,
    required this.level,
    required this.recommendation,
    required this.tips,
    required this.factors,
    required this.bestTimeWindows,
    required this.calculatedAt,
  });

  factory BiteForecastModel.fromJson(Map<String, dynamic> json) {
    return BiteForecastModel(
      overallActivity: (json['overallActivity'] ?? 0.0).toDouble(),
      scorePoints: json['scorePoints'] ?? 0,
      level: BiteForecastLevel.values.firstWhere(
            (e) => e.toString() == json['level'],
        orElse: () => BiteForecastLevel.poor,
      ),
      recommendation: json['recommendation'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      factors: (json['factors'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, BiteFactor.fromJson(value))),
      bestTimeWindows: (json['bestTimeWindows'] as List<dynamic>? ?? [])
          .map((item) => OptimalTimeWindow.fromJson(item))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallActivity': overallActivity,
      'scorePoints': scorePoints,
      'level': level.toString(),
      'recommendation': recommendation,
      'tips': tips,
      'factors': factors.map((key, value) => MapEntry(key, value.toJson())),
      'bestTimeWindows': bestTimeWindows.map((window) => window.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}

enum BiteForecastLevel {
  excellent, // 80-100
  good,      // 60-79
  moderate,  // 40-59
  poor,      // 20-39
  veryPoor   // 0-19
}

class BiteFactor {
  final String name;
  final double value; // 0.0 - 1.0
  final double weight; // Важность фактора
  final FactorImpact impact;
  final String description;

  BiteFactor({
    required this.name,
    required this.value,
    required this.weight,
    required this.impact,
    required this.description,
  });

  factory BiteFactor.fromJson(Map<String, dynamic> json) {
    return BiteFactor(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      impact: FactorImpact.values.firstWhere(
            (e) => e.toString() == json['impact'],
        orElse: () => FactorImpact.neutral,
      ),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'weight': weight,
      'impact': impact.toString(),
      'description': description,
    };
  }
}

enum FactorImpact {
  veryPositive,
  positive,
  neutral,
  negative,
  veryNegative
}

class OptimalTimeWindow {
  final DateTime startTime;
  final DateTime endTime;
  final double activity; // 0.0 - 1.0
  final String reason;
  final List<String> recommendations;

  OptimalTimeWindow({
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.reason,
    required this.recommendations,
  });

  factory OptimalTimeWindow.fromJson(Map<String, dynamic> json) {
    return OptimalTimeWindow(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      activity: (json['activity'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'activity': activity,
      'reason': reason,
      'recommendations': recommendations,
    };
  }

  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }
}

// Расширения для удобства работы
extension BiteForecastLevelExtension on BiteForecastLevel {
  String get displayName {
    switch (this) {
      case BiteForecastLevel.excellent:
        return 'excellent_activity';
      case BiteForecastLevel.good:
        return 'good_activity';
      case BiteForecastLevel.moderate:
        return 'moderate_activity';
      case BiteForecastLevel.poor:
        return 'poor_activity';
      case BiteForecastLevel.veryPoor:
        return 'very_poor_activity';
    }
  }

  int get minScore {
    switch (this) {
      case BiteForecastLevel.excellent:
        return 80;
      case BiteForecastLevel.good:
        return 60;
      case BiteForecastLevel.moderate:
        return 40;
      case BiteForecastLevel.poor:
        return 20;
      case BiteForecastLevel.veryPoor:
        return 0;
    }
  }

  int get maxScore {
    switch (this) {
      case BiteForecastLevel.excellent:
        return 100;
      case BiteForecastLevel.good:
        return 79;
      case BiteForecastLevel.moderate:
        return 59;
      case BiteForecastLevel.poor:
        return 39;
      case BiteForecastLevel.veryPoor:
        return 19;
    }
  }
}

extension FactorImpactExtension on FactorImpact {
  double get multiplier {
    switch (this) {
      case FactorImpact.veryPositive:
        return 1.2;
      case FactorImpact.positive:
        return 1.1;
      case FactorImpact.neutral:
        return 1.0;
      case FactorImpact.negative:
        return 0.9;
      case FactorImpact.veryNegative:
        return 0.8;
    }
  }
}