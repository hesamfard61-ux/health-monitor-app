import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jalali_utils.dart';

/// دسترسی به حساس گام‌شمار گوشی
class PedometerService {
  PedometerService._();
  static final PedometerService instance = PedometerService._();

  /// یک قرائت از شمارنده کل سیستم (از زمان روشن شدن گوشی)
  Future<int?> readOnce() async {
    try {
      final c = Completer<int?>();
      late final StreamSubscription<StepCount> sub;
      sub = Pedometer.stepCountStream.listen(
        (e) {
          if (!c.isCompleted) c.complete(e.steps);
        },
        onError: (Object _) {
          if (!c.isCompleted) c.complete(null);
        },
        cancelOnError: true,
      );
      final v = await c.future.timeout(const Duration(seconds: 4), onTimeout: () => null);
      await sub.cancel();
      return v;
    } catch (_) {
      return null;
    }
  }

  /// قدم‌های امروز: از اختلاف شمارنده کل با خط پایه ذخیره‌شده برای امروز.
  /// اگر سنسور در دسترس نباشد -1 برمی‌گردد.
  Future<int> sensorStepsToday() async {
    final raw = await readOnce();
    if (raw == null) return -1;
    final p = await SharedPreferences.getInstance();
    final today = jTodayKey();
    final day = p.getString('ped_day') ?? '';
    final base = p.getInt('ped_base');
    if (day != today || base == null || raw < base) {
      await p.setString('ped_day', today);
      await p.setInt('ped_base', raw);
      return 0;
    }
    return raw - base;
  }
}
