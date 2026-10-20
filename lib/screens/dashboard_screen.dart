import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';
import '../services/pedometer_service.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';
import '../widgets/common.dart';

/// صفحه ۱: داشبورد اصلی با خلاصه روز/هفته/ماه
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _range = 0; // 0=روز 1=هفته 2=ماه
  bool _checkingSensor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminder());
  }

  List<String> _rangeKeys() {
    switch (_range) {
      case 1:
        return lastNDayKeys(7);
      case 2:
        return lastNDayKeys(30);
      default:
        return [jTodayKey()];
    }
  }

  Future<void> _checkReminder() async {
    final s = context.read<SettingsProvider>();
    final h = context.read<HealthProvider>();
    if (!s.reminderEnabled || !h.loaded) return;
    final now = TimeOfDay.now();
    final parts = s.reminderTime.split(':');
    final rh = int.tryParse(parts[0]) ?? 20;
    final rm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final after = now.hour > rh || (now.hour == rh && now.minute >= rm);
    if (!after) return;
    if (h.sumOn(MetricType.water, jTodayKey()) >= s.waterGoal) return;
    final p = await SharedPreferences.getInstance();
    if (p.getString('last_reminder') == jTodayKey()) return;
    await p.setString('last_reminder', jTodayKey());
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('یادآوری ثبت آب'),
        content: Text(
          'امروز ${faNum(h.sumOn(MetricType.water, jTodayKey()))} لیوان آب ثبت کرده‌اید. '
          'هدف روزانه شما ${faNum(s.waterGoal)} لیوان است.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('باشه')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<HealthProvider>().add(Measurement(
                    type: MetricType.water,
                    value1: 1,
                    date: jTodayKey(),
                    time: timeNowKey(),
                    note: 'ثبت سریع یادآوری',
                  ));
            },
            child: const Text('ثبت یک لیوان'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSensor() async {
    setState(() => _checkingSensor = true);
    final v = await PedometerService.instance.sensorStepsToday();
    if (!mounted) return;
    setState(() => _checkingSensor = false);
    final msg = v < 0 ? 'حساس گام‌شمار در دسترس نیست' : 'قدم‌های امروز طبق حساس: ${faNum(v)}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final s = context.watch<SettingsProvider>();
    final today = jTodayKey();
    final keys = _rangeKeys();

    // مجموع‌های بازه انتخابی
    double totalSteps = 0;
    double totalWater = 0;
    double totalCal = 0;
    for (final k in keys) {
      totalSteps += h.stepsOn(k);
      totalWater += h.sumOn(MetricType.water, k);
      totalCal += h.caloriesOn(k);
    }
    final bmi = h.bmiValue;

    return Scaffold(
      appBar: AppBar(title: const Text('پایش سلامت')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.name.isEmpty ? 'سلام!' : 'سلام، ${s.name} عزیز',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(jFullDate(today), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('روز')),
              ButtonSegment(value: 1, label: Text('هفته')),
              ButtonSegment(value: 2, label: Text('ماه')),
            ],
            selected: {_range},
            onSelectionChanged: (v) => setState(() => _range = v.first),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              StatCard(
                icon: Icons.directions_walk,
                label: 'قدم${_range > 0 ? ' (مجموع)' : ''}',
                value: faNum(totalSteps),
                sub: 'هدف: ${faNum(_range > 0 ? s.stepGoal * keys.length : s.stepGoal)}',
                color: kMetrics[MetricType.steps]!.color,
                progress: totalSteps / (s.stepGoal * (_range > 0 ? keys.length : 1)),
                onTap: _checkingSensor ? null : _refreshSensor,
              ),
              StatCard(
                icon: Icons.local_fire_department,
                label: 'کالری${_range > 0 ? ' (مجموع)' : ''}',
                value: faNum(totalCal.round()),
                sub: 'کیلوکالری (پیاده‌روی)',
                color: Colors.deepOrange,
              ),
              StatCard(
                icon: Icons.local_drink,
                label: 'آب${_range > 0 ? ' (مجموع)' : ''}',
                value: faNum(totalWater),
                sub: 'هدف: ${faNum(_range > 0 ? s.waterGoal * keys.length : s.waterGoal)} لیوان',
                color: kMetrics[MetricType.water]!.color,
                progress: totalWater / (s.waterGoal * (_range > 0 ? keys.length : 1)),
              ),
              StatCard(
                icon: Icons.monitor_weight,
                label: 'شاخص توده بدنی (BMI)',
                value: bmi == null ? '—' : faNum(bmi),
                sub: bmi == null ? 'قد و وزن را ثبت کنید' : bmiCategory(bmi),
                color: bmi == null ? Colors.grey : bmiColor(bmi),
              ),
            ],
          ),
          SectionTitle('آخرین اندازه‌گیری‌ها'),
          if (h.loadError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(h.loadError!)),
            ),
          if (h.all.isEmpty)
            const EmptyState(
              icon: Icons.monitor_heart_outlined,
              message: 'هنوز داده‌ای ثبت نشده است.\nاز تب «ثبت داده» شروع کنید.',
            )
          else
            ...[for (final t in MetricType.values) h.latest(t)].whereType<Measurement>().map((m) {
              final def = kMetrics[m.type]!;
              final hist = h.of(m.type);
              double? change;
              if (hist.length >= 2) change = m.value1 - hist[1].value1;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: IconBadge(icon: def.icon, color: def.color),
                  title: Text(def.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${faDigits(m.date)} - ${faDigits(m.time)}', style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TrendIcon(change: change),
                      const SizedBox(width: 6),
                      Text(m.valueText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: def.color)),
                      const SizedBox(width: 4),
                      Text(def.unit, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
