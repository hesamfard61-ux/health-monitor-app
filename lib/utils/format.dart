const String _en = '0123456789';
const String _fa = '۰۱۲۳۴۵۶۷۸۹';

/// تبدیل ارقام انگلیسی به فارسی برای نمایش
String faDigits(String input) {
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final i = _en.indexOf(ch);
    b.write(i >= 0 ? _fa[i] : ch);
  }
  return b.toString();
}

/// تبدیل ارقام فارسی/عربی به انگلیسی برای پارس ورودی کاربر
String enDigits(String input) {
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final fi = _fa.indexOf(ch);
    if (fi >= 0) {
      b.write(_en[fi]);
    } else {
      final ai = '٠١٢٣٤٥٦٧٨٩'.indexOf(ch);
      b.write(ai >= 0 ? _en[ai] : ch);
    }
  }
  return b.toString();
}

/// قالب‌بندی عدد بدون صفرهای اضافی: 72.0 -> 72 و 72.5 -> 72.5
String fmtNum(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  String s = v.toStringAsFixed(1);
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s;
}

String faNum(num v) => faDigits(fmtNum(v));
