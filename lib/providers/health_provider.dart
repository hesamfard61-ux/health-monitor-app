import 'package:flutter/foundation.dart';
import '../models/measurement.dart';
import '../services/database_service.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';
import '../utils/jalali_utils.dart';

/// مدیریت داده‌های سلامت: CRUD، فیلتر، مرتب‌سازی، آمار
class HealthProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Measurement> _all = [];
  bool loaded = false;
  String? loadError;

  // فیلترها
  MetricType? filterType;
  String? filterFrom;
  String? filterTo;
  int filterPeriod = 0;
  String sortColumn = 'date';
  bool sortAsc = false;

  List<Measurement> get all => List.unmodifiable(_all);

  Future<void> load() async {
    try {
      _all = await _db.getAll();
      loaded = true;
      loadError = null;
    } catch (e) {
      loaded = true;
      loadError = 'خطا در خواندن پایگاه داده: $e';
    }
    notifyListeners();
  }

  Future<void> add(Measurement m) async {
    final id = await _db.insert(m);
    _all = [m.copyWith(id: id), ..._all];
    notifyListeners();
  }

  Future<void> update(Measurement m) async {
    await _db.update(m);
    _all = [for (final x in _all) if (x.id == m.id) m else x];
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    _all.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> replaceAll(List<Measurement> list) async {
    await _db.replaceAll(list);
    _all = list;
    notifyListeners();
  }

  // ---------- فیلتر و مرتب‌سازی ----------

  List<Measurement> get filtered {
    var list = [
      for (final m in _all)
        if ((filterType == null || m.type == filterType) &&
            (filterFrom == null || m.date.compareTo(filterFrom!) >= 0) &&
            (filterTo == null || m.date.compareTo(filterTo!) <= 0) &&
            timeInPeriod(m.time, filterPeriod))
          m
    ];
    int cmp(Measurement a, Measurement b) {
      switch (sortColumn) {
        case 'value':
          return a.value1.compareTo(b.value1);
        case 'type':
          return a.type.index.compareTo(b.type.index);
        default:
          final d = a.date.compareTo(b.date);
          return d != 0 ? d : a.time.compareTo(b.time);
      }
    }

    list.sort((a, b) => sortAsc ? cmp(a, b) : cmp(b, a));
    return list;
  }

  void sortBy(String col) {
    if (sortColumn == col) {
      sortAsc = !sortAsc;
    } else {
      sortColumn = col;
      sortAsc = false;
    }
    notifyListeners();
  }

  void setType(MetricType? t) {
    filterType = t;
    notifyListeners();
  }

  void setFrom(String? d) {
    filterFrom = d;
    notifyListeners();
  }

  void setTo(String? d) {
    filterTo = d;
    notifyListeners();
  }

  void setPeriod(int p) {
    filterPeriod = p;
    notifyListeners();
  }

  void clearFilters() {
    filterType = null;
    filterFrom = null;
    filterTo = null;
    filterPeriod = 0;
    notifyListeners();
  }

  // ---------- کوئری‌های آماری ----------

  /// آخرین اندازه‌گیری از هر نوع (لیست بر اساس تاریخ جدید است)
  Measurement? latest(MetricType t) {
    for (final m in _all) {
      if (m.type == t) return m;
    }
    return null;
  }

  List<Measurement> of(MetricType t) => [for (final m in _all) if (m.type == t) m];

  List<Measurement> onDate(String date) => [for (final m in _all) if (m.date == date) m];

  double sumOn(MetricType t, String date) {
    var s = 0.0;
    for (final m in onDate(date)) {
      if (m.type == t) s += m.value1;
    }
    return s;
  }

  double maxOn(MetricType t, String date) {
    var mx = 0.0;
    for (final m in onDate(date)) {
      if (m.type == t && m.value1 > mx) mx = m.value1;
    }
    return mx;
  }

  /// تجمیع یک روز برای نمودار: آب/قدم = مجموع، بقیه = میانگین
  double aggregateDay(MetricType t, String date) {
    final l = [for (final m in onDate(date)) if (m.type == t) m];
    if (l.isEmpty) return 0;
    final s = l.fold(0.0, (acc, m) => acc + m.value1);
    return kMetrics[t]!.isSum ? s : s / l.length;
  }

  double? get bmiValue {
    final h = latest(MetricType.height);
    final w = latest(MetricType.weight);
    if (h == null || w == null) return null;
    return calcBmi(w.value1, h.value1);
  }

  double get currentWeightKg => latest(MetricType.weight)?.value1 ?? 70.0;

  double get currentHeightCm => latest(MetricType.height)?.value1 ?? 170.0;

  int stepsOn(String date) => maxOn(MetricType.steps, date).toInt();

  double caloriesOn(String date) => calcCalories(steps: stepsOn(date), weightKg: currentWeightKg);

  Set<String> get entryDates => {for (final m in _all) m.date};

  List<Measurement> entriesInWindow(List<String> dates) =>
      [for (final m in _all) if (dates.contains(m.date)) m];
}
