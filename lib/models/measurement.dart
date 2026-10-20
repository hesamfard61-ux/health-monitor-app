import '../utils/constants.dart';

class Measurement {
  final int? id;
  final MetricType type;
  final double value1;
  final double? value2; // فقط برای فشار خون (دیاستولی)
  final String date; // 1403/07/29 (شمسی)
  final String time; // 14:35
  final String note;

  const Measurement({
    this.id,
    required this.type,
    required this.value1,
    this.value2,
    required this.date,
    required this.time,
    this.note = '',
  });

  Measurement copyWith({
    int? id,
    MetricType? type,
    double? value1,
    double? value2,
    String? date,
    String? time,
    String? note,
  }) =>
      Measurement(
        id: id ?? this.id,
        type: type ?? this.type,
        value1: value1 ?? this.value1,
        value2: value2 ?? this.value2,
        date: date ?? this.date,
        time: time ?? this.time,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'value1': value1,
        'value2': value2,
        'date': date,
        'time': time,
        'note': note,
      };

  factory Measurement.fromMap(Map<String, dynamic> map) => Measurement(
        id: map['id'] as int?,
        type: MetricType.values.byName(map['type'] as String),
        value1: (map['value1'] as num).toDouble(),
        value2: map['value2'] == null ? null : (map['value2'] as num).toDouble(),
        date: map['date'] as String,
        time: map['time'] as String,
        note: (map['note'] ?? '') as String,
      );

  String get valueText {
    final a = fmtNum(value1);
    if (kMetrics[type]!.dual) return '$a/${fmtNum(value2 ?? 0)}';
    return a;
  }
}
