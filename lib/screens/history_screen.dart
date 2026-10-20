import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/measurement.dart';
import '../providers/health_provider.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';
import '../widgets/common.dart';
import '../widgets/jalali_date_picker.dart';

/// صفحه ۳: جدول تاریخچه با فیلتر و مرتب‌سازی
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final cols = ['type', 'value', 'date', 'time'];
    final sortIndex = cols.indexOf(h.sortColumn);

    return Scaffold(
      appBar: AppBar(title: Text('تاریخچه (${faNum(h.filtered.length)} رکورد)')),
      body: Column(
        children: [
          _Filters(),
          Expanded(
            child: h.filtered.isEmpty
                ? const EmptyState(icon: Icons.filter_list_off, message: 'رکوردی با این فیلترها پیدا نشد')
                : Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
                          sortAscending: h.sortAsc,
                          columnSpacing: 18,
                          columns: [
                            DataColumn(label: const Text('نوع'), onSort: (_, __) => h.sortBy('type')),
                            DataColumn(label: const Text('مقدار'), onSort: (_, __) => h.sortBy('value')),
                            DataColumn(label: const Text('تاریخ'), onSort: (_, __) => h.sortBy('date')),
                            DataColumn(label: const Text('ساعت'), onSort: (_, __) => h.sortBy('time')),
                            const DataColumn(label: Text('یادداشت')),
                            const DataColumn(label: Text('عملیات')),
                          ],
                          rows: [
                            for (final m in h.filtered)
                              DataRow(cells: [
                                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(kMetrics[m.type]!.icon, size: 16, color: kMetrics[m.type]!.color),
                                  const SizedBox(width: 6),
                                  Text(kMetrics[m.type]!.label),
                                ])),
                                DataCell(Text(
                                  '${m.valueText} ${kMetrics[m.type]!.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text(faDigits(m.date))),
                                DataCell(Text(faDigits(m.time))),
                                DataCell(SizedBox(width: 110, child: Text(m.note.isEmpty ? '-' : m.note, overflow: TextOverflow.ellipsis))),
                                DataCell(Row(children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _edit(context, m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => _confirmDelete(context, m),
                                  ),
                                ])),
                              ]),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Measurement m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف رکورد'),
        content: Text('«${kMetrics[m.type]!.label}: ${m.valueText}» در تاریخ ${faDigits(m.date)} حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<HealthProvider>().remove(m.id!);
    }
  }

  Future<void> _edit(BuildContext context, Measurement m) async {
    final v1 = TextEditingController(text: fmtNum(m.value1));
    final v2 = TextEditingController(text: m.value2 == null ? '' : fmtNum(m.value2!));
    final note = TextEditingController(text: m.note);
    var date = m.date;
    var time = m.time;
    final def = kMetrics[m.type]!;
    final updated = await showDialog<Measurement>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('ویرایش ${def.label}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              TextField(
                controller: v1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: def.dual ? 'سیستولی (بالا)' : 'مقدار (${def.unit})'),
              ),
              if (def.dual) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: v2,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'دیاستولی (پایین)'),
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showJalaliDatePicker(ctx, initial: jParse(date));
                      if (d != null) setD(() => date = jKey(d));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'تاریخ', suffixIcon: Icon(Icons.calendar_month, size: 18)),
                      child: Text(faDigits(date), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final parts = time.split(':');
                      final t = await showTimePicker(
                        ctx,
                        initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 12, minute: int.tryParse(parts[1]) ?? 0),
                      );
                      if (t != null) setD(() => time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'ساعت', suffixIcon: Icon(Icons.access_time, size: 18)),
                      child: Text(faDigits(time), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'یادداشت')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            FilledButton(
              onPressed: () {
                final nv1 = double.tryParse(enDigits(v1.text.trim()));
                if (nv1 == null) return;
                double? nv2;
                if (def.dual) {
                  nv2 = double.tryParse(enDigits(v2.text.trim()));
                  if (nv2 == null) return;
                }
                Navigator.pop(
                  ctx,
                  m.copyWith(value1: nv1, value2: def.dual ? nv2 : null, date: date, time: time, note: note.text.trim()),
                );
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    if (updated != null && context.mounted) {
      await context.read<HealthProvider>().update(updated);
    }
  }
}

/// نوار فیلترها: نوع، بازه تاریخ شمسی، زمان روز
class _Filters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final hasFilter = h.filterType != null || h.filterFrom != null || h.filterTo != null || h.filterPeriod > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<MetricType?>(
                value: h.filterType,
                isDense: true,
                decoration: const InputDecoration(labelText: 'نوع اندازه‌گیری', prefixIcon: Icon(Icons.filter_list, size: 18)),
                items: [
                  const DropdownMenuItem<MetricType?>(child: Text('همه انواع')),
                  for (final e in kMetrics.entries)
                    DropdownMenuItem<MetricType?>(value: e.key, child: Text(e.value.label)),
                ],
                onChanged: (v) => h.setType(v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: h.filterPeriod,
                isDense: true,
                decoration: const InputDecoration(labelText: 'زمان روز', prefixIcon: Icon(Icons.schedule, size: 18)),
                items: [
                  for (int i = 0; i < kPeriodNames.length; i++)
                    DropdownMenuItem<int>(value: i, child: Text(kPeriodNames[i])),
                ],
                onChanged: (v) => h.setPeriod(v ?? 0),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dateField(context, label: 'از تاریخ', value: h.filterFrom, onPick: (d) => h.setFrom(d), onClear: () => h.setFrom(null))),
            const SizedBox(width: 10),
            Expanded(child: _dateField(context, label: 'تا تاریخ', value: h.filterTo, onPick: (d) => h.setTo(d), onClear: () => h.setTo(null))),
          ]),
          if (hasFilter)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => h.clearFilters(),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('پاک کردن فیلترها', style: TextStyle(fontSize: 12)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required String? value,
    required ValueChanged<String> onPick,
    required VoidCallback onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final d = await showJalaliDatePicker(context, initial: value == null ? Jalali.now() : jParse(value));
        if (d != null) onPick(jKey(d));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: value == null ? label : '$label: ${faDigits(value)}',
          prefixIcon: const Icon(Icons.calendar_month, size: 18),
          suffixIcon: value == null
              ? null
              : IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onClear),
        ),
        child: value == null ? const SizedBox(height: 8) : const SizedBox(height: 8),
      ),
    );
  }
}
