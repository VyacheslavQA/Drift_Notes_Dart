// Путь: lib/models/fishing_bite_chart_model.dart

class FishingBiteChartModel {
  final String id;
  final int dayIndex; // Индекс дня рыбалки (0 - первый день, 1 - второй и т.д.)
  final String chartType; // Тип графика из шаблонов
  final String chartName; // Название графика
  final Map<String, double> biteIntensityByHour; // Часы и интенсивность клёва
  final String notes; // Заметки по графику

  FishingBiteChartModel({
    required this.id,
    required this.dayIndex,
    required this.chartType,
    required this.chartName,
    required this.biteIntensityByHour,
    this.notes = '',
  });

  // Создание пустого объекта с данными по умолчанию
  factory FishingBiteChartModel.empty(String id, int dayIndex) {
    return FishingBiteChartModel(
      id: id,
      dayIndex: dayIndex,
      chartType: 'normal',
      chartName: 'Обычный клёв',
      biteIntensityByHour: {
        '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.1, '04': 0.2,
        '05': 0.3, '06': 0.5, '07': 0.6, '08': 0.7, '09': 0.6,
        '10': 0.5, '11': 0.4, '12': 0.3, '13': 0.4, '14': 0.5,
        '15': 0.6, '16': 0.7, '17': 0.8, '18': 0.7, '19': 0.6,
        '20': 0.4, '21': 0.3, '22': 0.2, '23': 0.1
      },
    );
  }

  // Преднастроенные шаблоны графиков клёва
  static Map<String, Map<String, double>> chartTemplates = {
    'morning': { // Утренний клёв
      '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.2, '04': 0.4,
      '05': 0.7, '06': 0.9, '07': 1.0, '08': 0.9, '09': 0.7,
      '10': 0.5, '11': 0.3, '12': 0.2, '13': 0.1, '14': 0.1,
      '15': 0.1, '16': 0.1, '17': 0.2, '18': 0.3, '19': 0.2,
      '20': 0.1, '21': 0.1, '22': 0.1, '23': 0.1
    },
    'evening': { // Вечерний клёв
      '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.1, '04': 0.1,
      '05': 0.1, '06': 0.1, '07': 0.2, '08': 0.2, '09': 0.2,
      '10': 0.1, '11': 0.1, '12': 0.2, '13': 0.3, '14': 0.4,
      '15': 0.5, '16': 0.7, '17': 0.9, '18': 1.0, '19': 0.9,
      '20': 0.7, '21': 0.5, '22': 0.3, '23': 0.2
    },
    'noon': { // Дневной клёв
      '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.1, '04': 0.1,
      '05': 0.2, '06': 0.2, '07': 0.3, '08': 0.4, '09': 0.5,
      '10': 0.7, '11': 0.9, '12': 1.0, '13': 0.9, '14': 0.7,
      '15': 0.5, '16': 0.4, '17': 0.3, '18': 0.2, '19': 0.2,
      '20': 0.1, '21': 0.1, '22': 0.1, '23': 0.1
    },
    'night': { // Ночной клёв
      '00': 0.6, '01': 0.7, '02': 0.9, '03': 1.0, '04': 0.8,
      '05': 0.5, '06': 0.2, '07': 0.1, '08': 0.1, '09': 0.1,
      '10': 0.1, '11': 0.1, '12': 0.1, '13': 0.1, '14': 0.1,
      '15': 0.1, '16': 0.1, '17': 0.1, '18': 0.1, '19': 0.2,
      '20': 0.3, '21': 0.4, '22': 0.5, '23': 0.6
    },
    'weak': { // Слабый клёв
      '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.1, '04': 0.1,
      '05': 0.2, '06': 0.2, '07': 0.2, '08': 0.2, '09': 0.2,
      '10': 0.3, '11': 0.3, '12': 0.2, '13': 0.2, '14': 0.2,
      '15': 0.2, '16': 0.2, '17': 0.2, '18': 0.2, '19': 0.2,
      '20': 0.1, '21': 0.1, '22': 0.1, '23': 0.1
    },
    'active': { // Активный клёв весь день
      '00': 0.4, '01': 0.3, '02': 0.3, '03': 0.4, '04': 0.5,
      '05': 0.6, '06': 0.7, '07': 0.8, '08': 0.9, '09': 0.9,
      '10': 0.8, '11': 0.7, '12': 0.7, '13': 0.7, '14': 0.8,
      '15': 0.9, '16': 0.9, '17': 0.8, '18': 0.7, '19': 0.7,
      '20': 0.6, '21': 0.5, '22': 0.4, '23': 0.4
    },
    'normal': { // Обычный клёв
      '00': 0.1, '01': 0.1, '02': 0.1, '03': 0.1, '04': 0.2,
      '05': 0.3, '06': 0.5, '07': 0.6, '08': 0.7, '09': 0.6,
      '10': 0.5, '11': 0.4, '12': 0.3, '13': 0.4, '14': 0.5,
      '15': 0.6, '16': 0.7, '17': 0.8, '18': 0.7, '19': 0.6,
      '20': 0.4, '21': 0.3, '22': 0.2, '23': 0.1
    }
  };

  // Названия шаблонов на русском
  static Map<String, String> chartTemplateNames = {
    'morning': 'Утренний клёв',
    'evening': 'Вечерний клёв',
    'noon': 'Дневной клёв',
    'night': 'Ночной клёв',
    'weak': 'Слабый клёв',
    'active': 'Активный клёв',
    'normal': 'Обычный клёв',
  };

  // Создание модели из Map (для работы с Firebase)
  factory FishingBiteChartModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> biteIntensity = {};

    if (json['biteIntensityByHour'] != null) {
      final Map<String, dynamic> dataMap = json['biteIntensityByHour'];
      dataMap.forEach((key, value) {
        biteIntensity[key] = (value is double) ? value : (value as num).toDouble();
      });
    } else {
      // Если данных нет, используем стандартный шаблон
      biteIntensity = Map<String, double>.from(chartTemplates['normal']!);
    }

    return FishingBiteChartModel(
      id: json['id'] ?? '',
      dayIndex: json['dayIndex'] ?? 0,
      chartType: json['chartType'] ?? 'normal',
      chartName: json['chartName'] ?? 'Обычный клёв',
      biteIntensityByHour: biteIntensity,
      notes: json['notes'] ?? '',
    );
  }

  // Преобразование модели в Map для сохранения в Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayIndex': dayIndex,
      'chartType': chartType,
      'chartName': chartName,
      'biteIntensityByHour': biteIntensityByHour,
      'notes': notes,
    };
  }

  // Создание копии с обновлёнными полями
  FishingBiteChartModel copyWith({
    String? id,
    int? dayIndex,
    String? chartType,
    String? chartName,
    Map<String, double>? biteIntensityByHour,
    String? notes,
  }) {
    return FishingBiteChartModel(
      id: id ?? this.id,
      dayIndex: dayIndex ?? this.dayIndex,
      chartType: chartType ?? this.chartType,
      chartName: chartName ?? this.chartName,
      biteIntensityByHour: biteIntensityByHour ?? this.biteIntensityByHour,
      notes: notes ?? this.notes,
    );
  }
}