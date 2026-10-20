import 'package:flutter/material.dart';

enum MetricType { height, weight, bloodPressure, bloodSugar, spo2, heartRate, water, steps }

class MetricDef {
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final bool dual; // دو مقدار (فشار خون)
  final double min;
  final double max;
  final bool isSum; // تجمیع روزانه به‌صورت مجموع (آب/قدم)

  const MetricDef(this.label, this.unit, this.icon, this.color,
      {this.dual = false, required this.min, required this.max, this.isSum = false});
}

const Map<MetricType, MetricDef> kMetrics = {
  MetricType.height: MetricDef('قد', 'سانتی‌متر', Icons.height, Color(0xFF00897B), min: 50, max: 250),
  MetricType.weight: MetricDef('وزن', 'کیلوگرم', Icons.monitor_weight, Color(0xFF5E35B1), min: 2, max: 300),
  MetricType.bloodPressure: MetricDef('فشار خون', 'mmHg', Icons.favorite, Color(0xFFE53935), dual: true, min: 40, max: 260),
  MetricType.bloodSugar: MetricDef('قند خون', 'mg/dL', Icons.water_drop, Color(0xFFFB8C00), min: 20, max: 600),
  MetricType.spo2: MetricDef('اکسیژن خون', '٪', Icons.air, Color(0xFF1E88E5), min: 50, max: 100),
  MetricType.heartRate: MetricDef('ضربان قلب', 'ضربه در دقیقه', Icons.monitor_heart, Color(0xFFD81B60), min: 30, max: 220),
  MetricType.water: MetricDef('آب', 'لیوان', Icons.local_drink, Color(0xFF00ACC1), min: 0, max: 50, isSum: true),
  MetricType.steps: MetricDef('قدم', 'قدم', Icons.directions_walk, Color(0xFF43A047), min: 0, max: 200000, isSum: true),
};

/// بازه‌های زمانی روز: 0=همه، 1=صبح، 2=ظهر، 3=عصر، 4=شب
const List<String> kPeriodNames = ['همه', 'صبح', 'ظهر', 'عصر', 'شب'];

int periodOfTime(String time) {
  final h = int.tryParse(time.split(':').first) ?? 0;
  if (h >= 4 && h < 12) return 1;
  if (h >= 12 && h < 16) return 2;
  if (h >= 16 && h < 20) return 3;
  return 4;
}

bool timeInPeriod(String time, int period) {
  if (period <= 0) return true;
  return periodOfTime(time) == period;
}

const List<String> kChartTypes = ['خطی', 'میله‌ای', 'دایره‌ای', 'ترکیبی'];
const List<String> kRanges = ['امروز', 'هفته', 'ماه', 'همه'];
