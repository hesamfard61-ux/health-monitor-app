import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/measurement.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';
import '../widgets/common.dart';
import '../widgets/jalali_date_picker.dart';

/// صفحه ۵: تقویم شمسی + تنظیمات، اهداف، خروجی و پشتیبان
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Jalali? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = Jalali.now();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _runExport(Future<File> Function() make, String text) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('در حال آماده‌سازی فایل...')]),
      ),
    );
    try {
      final f = await make();
      if (!mounted) return;
      Navigator.pop(context);
      await ExportService.share(f, text);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack('خطا در ساخت فایل: $e');
    }
  }

  Future<void> _restore() async {
    try {
      final list = await ExportService.importBackup();
      if (list == null) return;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('بازیابی پشتیبان'),
          content: Text('${faNum(list.length)} رکورد از فایل خوانده شد. همه داده‌های فعلی جایگزین می‌شوند. مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بازیابی')),
          ],
        ),
      );
      if (ok == true && mounted) {
        await context.read<HealthProvider>().replaceAll(list);
        _snack('بازیابی انجام شد');
      }
    } catch (e) {
      _snack('خطا در بازیابی: فایل معتبر نیست');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('تقویم و تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- تقویم شمسی ----------
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: JalaliMonthPicker(
                initial: Jalali.now(),
                markedDates: h.entryDates,
                onDaySelected: (d) => setState(() => _selectedDay = d),
              ),
            ),
          ),
          if (_selectedDay != null) ...[
            const SizedBox(height: 4),
            SectionTitle('رکوردهای روز ${jFullDate(jKey(_selectedDay!))}'),
            ...h.onDate(jKey(_selectedDay!)).map((m) {
              final d = kMetrics[m.type]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: IconBadge(icon: d.icon, color: d.color, size: 18),
                  title: Text('${d.label}: ${m.valueText} ${d.unit}'),
                  subtitle: m.note.isEmpty ? Text(faDigits(m.time)) : Text('${faDigits(m.time)} - ${m.note}'),
                ),
              );
            }),
            if (h.onDate(jKey(_selectedDay!)).isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('این روز رکوردی ندارد', style: TextStyle(fontSize: 12)),
              ),
          ],

          // ---------- پروفایل ----------
          SectionTitle('پروفایل'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                  controller: TextEditingController(text: s.name),
                  decoration: const InputDecoration(labelText: 'نام'),
                  onChanged: (v) => s.setName(v),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: s.age == 0 ? '' : faDigits(s.age.toString())),
                      decoration: const InputDecoration(labelText: 'سن'),
                      onChanged: (v) {
                        final n = int.tryParse(enDigits(v));
                        if (n != null && n > 0 && n < 130) s.setAge(n);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: s.gender,
                      decoration: const InputDecoration(labelText: 'جنسیت'),
                      items: const [
                        DropdownMenuItem(value: 'نامشخص', child: Text('نامشخص')),
                        DropdownMenuItem(value: 'مرد', child: Text('مرد')),
                        DropdownMenuItem(value: 'زن', child: Text('زن')),
                      ],
                      onChanged: (v) => s.setGender(v ?? 'نامشخص'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),

          // ---------- اهداف روزانه ----------
          SectionTitle('اهداف روزانه'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: faDigits(s.waterGoal.toString())),
                    decoration: const InputDecoration(labelText: 'لیوان آب در روز'),
                    onChanged: (v) {
                      final n = int.tryParse(enDigits(v));
                      if (n != null && n > 0) s.setWaterGoal(n);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: faDigits(s.stepGoal.toString())),
                    decoration: const InputDecoration(labelText: 'قدم در روز'),
                    onChanged: (v) {
                      final n = int.tryParse(enDigits(v));
                      if (n != null && n > 0) s.setStepGoal(n);
                    },
                  ),
                ),
              ]),
            ),
          ),

          // ---------- یادآوری ----------
          SectionTitle('یادآوری'),
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text('یادآوری روزانه ثبت آب'),
                subtitle: const Text('هنگام باز کردن اپ در زمان تعیین‌شده یادآوری می‌شود', style: TextStyle(fontSize: 11)),
                value: s.reminderEnabled,
                onChanged: (v) => s.setReminderEnabled(v),
              ),
              ListTile(
                enabled: s.reminderEnabled,
                title: const Text('ساعت یادآوری'),
                trailing: Text(faDigits(s.reminderTime)),
                onTap: () async {
                  final parts = s.reminderTime.split(':');
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0),
                  );
                  if (t != null) {
                    s.setReminderTime('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                  }
                },
              ),
            ]),
          ),

          // ---------- نمایش ----------
          SectionTitle('نمایش'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('حالت نمایش'),
              trailing: DropdownButton<ThemeMode>(
                value: s.themeMode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('سیستم')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('روشن')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('تیره')),
                ],
                onChanged: (v) => s.setThemeMode(v ?? ThemeMode.system),
              ),
            ),
          ),

          // ---------- داده‌ها ----------
          SectionTitle('داده‌ها و خروجی'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _runExport(
                        () => ExportService.exportPdf(h.all), 'گزارش PDF پایش سلامت'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('خروجی PDF (همه رکوردها)'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _runExport(
                        () => ExportService.exportExcel(h.all), 'گزارش Excel پایش سلامت'),
                    icon: const Icon(Icons.grid_on),
                    label: const Text('خروجی Excel (همه رکوردها)'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _runExport(
                        () => ExportService.exportBackup(h.all), 'فایل پشتیبان پایش سلامت'),
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('پشتیبان‌گیری (JSON)'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _restore,
                    icon: const Icon(Icons.restore),
                    label: const Text('بازیابی از پشتیبان'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'فایل‌ها از طریق اشتراک‌گذاری اندروید قابل ذخیره در گالری/گوگل‌درایو/پیام‌رسان‌ها هستند.',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                ),
              ]),
            ),
          ),

          // ---------- درباره ----------
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('پایش سلامت نسخه ۱٫۰٫۰'),
              subtitle: const Text('اپلیکیشن شخصی سلامت با تقویم شمسی — داده‌ها فقط روی گوشی شما ذخیره می‌شود'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
