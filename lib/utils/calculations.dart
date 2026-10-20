import 'package:flutter/material.dart';

/// محاسبات استاندارد سلامت: BMI، کالری، مسافت

double calcBmi(double weightKg, double heightCm) {
  final m = heightCm / 100;
  if (m <= 0 || weightKg <= 0) return 0;
  return weightKg / (m * m);
}

String bmiCategory(double bmi) {
  if (bmi < 18.5) return 'کمبود وزن';
  if (bmi < 25) return 'وزن نرمال';
  if (bmi < 30) return 'اضافه وزن';
  return 'چاقی';
}

Color bmiColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFF1E88E5);
  if (bmi < 25) return const Color(0xFF43A047);
  if (bmi < 30) return const Color(0xFFFB8C00);
  return const Color(0xFFE53935);
}

/// کالری بر اساس فرمول استاندارد MET:
/// kcal = MET × 3.5 × وزن(kg) ÷ 200 × زمان(دقیقه)
/// MET پیاده‌روی تند = 3.8 و زمان تخمینی از سرعت ۱۰۰ قدم در دقیقه
double calcCalories({required int steps, required double weightKg, double met = 3.8, double cadencePerMin = 100}) {
  if (steps <= 0 || weightKg <= 0) return 0;
  final minutes = steps / cadencePerMin;
  return met * 3.5 * weightKg / 200 * minutes;
}

double kcalPerStep(double weightKg, {double met = 3.8, double cadencePerMin = 100}) =>
    calcCalories(steps: cadencePerMin, weightKg: weightKg, met: met, cadencePerMin: cadencePerMin) / cadencePerMin;

/// طول قدم تقریبی بر اساس قد (حدود ۴۱٪ قد) — متر
double strideLength(double heightCm) => heightCm > 0 ? heightCm * 0.414 / 100 : 0.70;

double distanceKm(int steps, double heightCm) => steps * strideLength(heightCm) / 1000;

/// محدوده نرمال هر شاخص برای نمایش راهنما
String normalHint(int index) {
  switch (index) {
    case 2: // فشار
      return 'نرمال: کمتر از 120/80';
    case 3: // قند
      return 'ناشتا: 70 تا 99';
    case 4: // اکسیژن
      return 'نرمال: 95 تا 100';
    case 5: // ضربان
      return 'نرمال استراحت: 60 تا 100';
    default:
      return '';
  }
}
