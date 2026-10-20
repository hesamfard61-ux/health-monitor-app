import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/measurement.dart';
import '../providers/health_provider.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';
import '../services/pedometer_service.dart';
import '../widgets/common.dart';
import '../widgets/jalali_date_picker.dart';

/// صفحه ۲: ثبت داده جدید با فرم فارسی و تاریخ شمسی
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  MetricType _type = MetricType.weight;
  final _v1 = TextEditingController();
  final _v2 = TextEditingController();
  final _note = TextEditingController();
  late String _date;
  late String _time;
  bool _readingSensor = false;

  @override
  void initState() {
    super.initState();
    _date = jTodayKey();
    _time = timeNowKey();
  }

  @override
  void dispose() {
    _v1.dispose();
    _v2.dispose();
    _note.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final d = await showJalaliDatePicker(context, initial: jParse(_date), markedDates: context.read<HealthProvider>().entryDates);
    if (d != null) setState(() => _date = jKey(d));
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0),
    );
    if (t != null) {
      setState(() => _time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _readSensor() async {
    setState(() => _readingSensor = true);
    try {
      if (await Permission.activityRecognition.isDenied) {
        await Permission.activityRecognition.request();
      }
      final v = await PedometerService.instance.sensorStepsToday();
      if (!mounted) return;
      if (v < 0) {
        _snack('حساس گام‌شمار در دسترس نیست؛ مقدار را دستی وارد کنید');
      } else {
        _v1.text = v.toString();
        _snack('قدم‌های امروز طبق حساس: ${faNum(v)}');
      }
    } finally {
      if (mounted) setState(() => _readingSensor = false);
    }
  }

  Future<void> _save() async {
    final def = kMetrics[_type];
    final raw1 = enDigits(_v1.text.trim());
    final v1 = double.tryParse(raw1);
    if (v1 == null) {
      _snack('لطفاً مقدار را وارد کنید');
      return;
    }
    if (v1 < def!.min || v1 > def.max) {
      _snack('مقدار باید بین ${faNum(def.min)} و ${faNum(def.max)} ${def.unit} باشد');
      return;
    }
    double? v2;
    if (def.dual) {
      v2 = double.tryParse(enDigits(_v2.text.trim()));
      if (v2 == null) {
        _snack('مقدار دیاستولی را وارد کنید');
        return;
      }
      if (v2 < 30 || v2 > 180) {
        _snack('دیاستولی باید بین ۳۰ تا ۱۸۰ باشد');
        return;
      }
      if (v2 >= v1) {
        _snack('سیستولی (بالا) باید بیشتر از دیاستولی (پایین) باشد');
        return;
      }
    }
    await context.read<HealthProvider>().add(Measurement(
          type: _type,
          value1: v1,
          value2: v2,
          date: _date,
          time: _time,
          note: _note.text.trim(),
        ));
    if (!mounted) return;
    _snack('ثبت شد');
    setState(() {
      _v1.clear();
      _v2.clear();
      _note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final def = kMetrics[_type]!;
    final hint = normalHint(MetricType.values.indexOf(_type));

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت داده جدید')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // انتخاب شاخص
          SectionTitle('نوع اندازه‌گیری'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in MetricType.values)
                ChoiceChip(
                  avatar: Icon(kMetrics[t]!.icon, size: 16, color: _type == t ? Colors.white : kMetrics[t]!.color),
                  label: Text(kMetrics[t]!.label),
                  selected: _type == t,
                  selectedColor: kMetrics[t]!.color,
                  labelStyle: TextStyle(color: _type == t ? Colors.white : null),
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // مقدارها
          SectionTitle('مقدار (${def.unit})'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _v1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: def.dual ? 'سیستولی (بالا)' : 'مقدار',
                  hintText: hint,
                ),
              ),
            ),
            if (def.dual) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _v2,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'دیاستولی (پایین)'),
                ),
              ),
            ],
            if (_type == MetricType.steps) ...[
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'خواندن از حساس گام‌شمار',
                onPressed: _readingSensor ? null : _readSensor,
                icon: _readingSensor
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sensors),
              ),
            ],
          ]),
          const SizedBox(height: 16),

          // تاریخ و ساعت شمسی
          Row(children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'تاریخ', suffixIcon: Icon(Icons.calendar_month)),
                  child: Text(faDigits(_date)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'ساعت', suffixIcon: Icon(Icons.access_time)),
                  child: Text(faDigits(_time)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)', hintText: 'مثلاً: ناشتا، بعد از ورزش...'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('ثبت اندازه‌گیری'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 24),

          // ثبت‌های امروز
          SectionTitle('ثبت‌های امروز'),
          if (h.onDate(jTodayKey()).isEmpty)
            const EmptyState(icon: Icons.event_available, message: 'امروز رکوردی ثبت نشده است')
          else
            ...h.onDate(jTodayKey()).map((m) {
              final d = kMetrics[m.type]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: IconBadge(icon: d.icon, color: d.color, size: 18),
                  title: Text('${d.label}: ${m.valueText} ${d.unit}'),
                  subtitle: m.note.isEmpty ? Text(faDigits(m.time)) : Text('${faDigits(m.time)} - ${m.note}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => h.remove(m.id!),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
