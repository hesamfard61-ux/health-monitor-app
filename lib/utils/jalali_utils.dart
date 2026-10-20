import 'package:shamsi_date/shamsi_date.dart';
import 'format.dart';

/// کلید استاندارد تاریخ شمسی: 1403/07/29 (قابل مقایسه رشته‌ای و مرتب‌سازی)
String jKey(Jalali j) {
  final m = j.month.toString().padLeft(2, '0');
  final d = j.day.toString().padLeft(2, '0');
  return '${j.year}/$m/$d';
}

String jKeyOf(DateTime dt) => jKey(Jalali.fromDateTime(dt));

String jTodayKey() => jKey(Jalali.now());

Jalali jParse(String key) {
  final p = key.split('/');
  return Jalali(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String jMonthName(int m) => Jalali(1400, m, 1).formatter.mN;

String jWeekdayName(Jalali j) => j.formatter.wN;

/// تاریخ کامل امروز: «دوشنبه ۲۹ مهر ۱۴۰۳»
String jFullDate(String key) {
  final j = jParse(key);
  return '${j.formatter.wN} ${faNum(j.day)} ${j.formatter.mN} ${faNum(j.year)}';
}

/// کلیدهای n روز اخیر (قدیمی‌ترین تا جدیدترین)
List<String> lastNDayKeys(int n) {
  final now = Jalali.now();
  final list = <String>[];
  for (int i = n - 1; i >= 0; i--) {
    final dt = now.toDateTime().add(Duration(days: -i));
    list.add(jKey(Jalali.fromDateTime(dt)));
  }
  return list;
}

/// جابه‌جایی ماه‌ها با اصلاح روز (مثلاً 31 فروردین -> 30 اردیبهشت)
Jalali shiftMonths(Jalali j, int delta) {
  int y = j.year;
  int m = j.month + delta;
  while (m > 12) {
    m -= 12;
    y++;
  }
  while (m < 1) {
    m += 12;
    y--;
  }
  int d = j.day;
  final maxLen = Jalali(y, m, 1).monthLength;
  if (d > maxLen) d = maxLen;
  return Jalali(y, m, d);
}

String monthKeyOf(String dateKey) {
  final p = dateKey.split('/');
  return '${p[0]}/${p[1]}';
}

String timeNowKey() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}
