import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';

/// تقویم شمسی (جلالی) با قابلیت علامت‌گذاری روزهای دارای رکورد
class JalaliMonthPicker extends StatefulWidget {
  final Jalali initial;
  final Set<String>? markedDates;
  final ValueChanged<Jalali>? onDaySelected;
  final bool showActions;

  const JalaliMonthPicker({
    super.key,
    required this.initial,
    this.markedDates,
    this.onDaySelected,
    this.showActions = false,
  });

  @override
  State<JalaliMonthPicker> createState() => _JalaliMonthPickerState();
}

class _JalaliMonthPickerState extends State<JalaliMonthPicker> {
  late Jalali _current;
  Jalali? _selected;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _selected = widget.initial;
  }

  void _shift(int delta) => setState(() => _current = shiftMonths(_current, delta));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthLen = _current.monthLength;
    final first = Jalali(_current.year, _current.month, 1);
    final offset = first.weekDay - 1; // 1 = شنبه
    final today = Jalali.now();
    final cells = <Widget>[];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= monthLen; d++) {
      final day = Jalali(_current.year, _current.month, d);
      final key = jKey(day);
      final isSel = _selected != null && jKey(_selected!) == key;
      final isToday = jKey(today) == key;
      final marked = widget.markedDates?.contains(key) ?? false;
      cells.add(InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _selected = day);
          widget.onDaySelected?.call(day);
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSel ? scheme.primary : null,
            border: (isToday && !isSel) ? Border.all(color: scheme.primary, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                faNum(d),
                style: TextStyle(
                  fontSize: 13,
                  color: isSel ? scheme.onPrimary : null,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              if (marked)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSel ? scheme.onPrimary : scheme.primary,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        ),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(-1), tooltip: 'ماه قبل'),
            Text(
              '${jMonthName(_current.month)} ${faNum(_current.year)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(1), tooltip: 'ماه بعد'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final w in ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'])
              Expanded(
                child: Center(
                  child: Text(w, style: TextStyle(fontSize: 11, color: scheme.outline)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 0.95,
          children: cells,
        ),
        if (widget.showActions)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  final t = Jalali.now();
                  setState(() {
                    _current = t;
                    _selected = t;
                  });
                },
                child: const Text('امروز'),
              ),
              Row(children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
                const SizedBox(width: 4),
                FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('تأیید')),
              ]),
            ],
          ),
      ],
    );
  }
}

/// باز کردن دیالوگ انتخاب تاریخ شمسی
Future<Jalali?> showJalaliDatePicker(
  BuildContext context, {
  required Jalali initial,
  Set<String>? markedDates,
}) {
  return showDialog<Jalali>(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: JalaliMonthPicker(initial: initial, markedDates: markedDates, showActions: true),
      ),
    ),
  );
}
