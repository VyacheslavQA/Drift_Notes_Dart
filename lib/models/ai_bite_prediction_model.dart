// Путь: lib/models/ai_bite_prediction_model.dart

import '../services/ai_bite_prediction_service.dart';

class AIBitePrediction {
  final int overallScore; // 0-100
  final ActivityLevel activityLevel;
  final double confidence; // 0.0-1.0
  final String recommendation;
  final String detailedAnalysis;
  final List<BiteFactorAnalysis> factors;
  final List<OptimalTimeWindow> bestTimeWindows;
  final List<String> tips;
  final DateTime generatedAt;
  final String dataSource; // 'local_ai', 'cloud_ai', 'hybrid'
  final String modelVersion;

  AIBitePrediction({
    required this.overallScore,
    required this.activityLevel,
    required this.confidence,
    required this.recommendation,
    required this.detailedAnalysis,
    required this.factors,
    required this.bestTimeWindows,
    required this.tips,
    required this.generatedAt,
    required this.dataSource,
    required this.modelVersion,
  });

  factory AIBitePrediction.fromJson(Map<String, dynamic> json) {
    return AIBitePrediction(
      overallScore: json['overallScore'] ?? 0,
      activityLevel: ActivityLevel.values.firstWhere(
            (e) => e.toString() == json['activityLevel'],
        orElse: () => ActivityLevel.moderate,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? '',
      factors: (json['factors'] as List<dynamic>? ?? [])
          .map((item) => BiteFactorAnalysis.fromJson(item))
          .toList(),
      bestTimeWindows: (json['bestTimeWindows'] as List<dynamic>? ?? [])
          .map((item) => OptimalTimeWindow.fromJson(item))
          .toList(),
      tips: List<String>.from(json['tips'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
      dataSource: json['dataSource'] ?? 'unknown',
      modelVersion: json['modelVersion'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'activityLevel': activityLevel.toString(),
      'confidence': confidence,
      'recommendation': recommendation,
      'detailedAnalysis': detailedAnalysis,
      'factors': factors.map((f) => f.toJson()).toList(),
      'bestTimeWindows': bestTimeWindows.map((w) => w.toJson()).toList(),
      'tips': tips,
      'generatedAt': generatedAt.toIso8601String(),
      'dataSource': dataSource,
      'modelVersion': modelVersion,
    };
  }
}

class BiteFactorAnalysis {
  final String name;
  final String value;
  final int impact; // -100 to +100
  final double weight; // 0.0 to 1.0
  final String description;
  final bool isPositive;

  BiteFactorAnalysis({
    required this.name,
    required this.value,
    required this.impact,
    required this.weight,
    required this.description,
    required this.isPositive,
  });

  factory BiteFactorAnalysis.fromJson(Map<String, dynamic> json) {
    return BiteFactorAnalysis(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      impact: json['impact'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      isPositive: json['isPositive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'impact': impact,
      'weight': weight,
      'description': description,
      'isPositive': isPositive,
    };
  }
}

class OptimalTimeWindow {
  final DateTime startTime;
  final DateTime endTime;
  final double activity; // 0.0-1.0
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