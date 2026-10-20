import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';
import '../widgets/common.dart';

/// صفحه ۴: نمودارهای تحلیلی (خطی/میله‌ای/دایره‌ای/ترکیبی)
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  MetricType _type = MetricType.weight;
  int _range = 1; // اندیس kRanges
  int _chartType = 0; // اندیس kChartTypes

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final def = kMetrics[_type]!;
    final data = _series(h);
    final scheme = Theme.of(context).colorScheme;

    final values = [for (final d in data) d.$2].where((v) => v > 0).toList();
    final isSum = def.isSum;

    return Scaffold(
      appBar: AppBar(title: const Text('نمودارها و تحلیل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<MetricType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'شاخص', prefixIcon: Icon(Icons.monitor_heart_outlined)),
            items: [
              for (final t in MetricType.values) DropdownMenuItem(value: t, child: Text(kMetrics[t]!.label)),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [for (int i = 0; i < kRanges.length; i++) ButtonSegment(value: i, label: Text(kRanges[i]))],
            selected: {_range},
            onSelectionChanged: (v) => setState(() => _range = v.first),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [for (int i = 0; i < kChartTypes.length; i++) ButtonSegment(value: i, label: Text(kChartTypes[i]))],
            selected: {_chartType},
            onSelectionChanged: (v) => setState(() => _chartType = v.first),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${def.label} - ${kRanges[_range]}${isSum ? ' (مجموع روزانه)' : ' (میانگین روزانه)'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (data.isEmpty)
                    const EmptyState(icon: Icons.show_chart, message: 'داده‌ای برای نمایش وجود ندارد')
                  else
                    SizedBox(height: 260, child: _buildChart(h, data, scheme)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (values.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('تعداد', faNum(values.length), scheme),
                _statChip(
                    isSum ? 'مجموع' : 'میانگین',
                    faNum(isSum ? values.fold(0.0, (a, b) => a + b) : values.fold(0.0, (a, b) => a + b) / values.length),
                    scheme),
                _statChip('بیشترین', faNum(values.reduce((a, b) => a > b ? a : b)), scheme),
                _statChip('کمترین', faNum(values.reduce((a, b) => a < b ? a : b)), scheme),
              ],
            ),
          if (_chartType == 3 && data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _type == MetricType.steps
                    ? 'ترکیبی: میله‌ها = قدم، خط = کالری (مقیاس نسبی)'
                    : 'ترکیبی: میله‌ها = مقدار، خط = میانگین متحرک',
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, ColorScheme scheme) {
    return Chip(
      avatar: Icon(Icons.info_outline, size: 16, color: scheme.primary),
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  // ---------- آماده‌سازی داده ----------

  List<(String, double)> _series(HealthProvider h) {
    switch (_range) {
      case 0: // امروز
        final list = h.of(_type).where((m) => m.date == jTodayKey()).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        return [for (final m in list) (m.time, m.value1)];
      case 3: // همه - ماهانه
        final buckets = <String, List<double>>{};
        for (final m in h.of(_type)) {
          buckets.putIfAbsent(monthKeyOf(m.date), () => []).add(m.value1);
        }
        final keys = buckets.keys.toList()..sort();
        return [
          for (final k in keys)
            (
              jMonthName(int.parse(k.split('/')[1])),
              kMetrics[_type]!.isSum
                  ? buckets[k]!.fold(0.0, (a, b) => a + b)
                  : buckets[k]!.fold(0.0, (a, b) => a + b) / buckets[k]!.length
            ),
        ];
      default: // هفته/ماه - روزانه
        final n = _range == 1 ? 7 : 30;
        final keys = lastNDayKeys(n);
        return [
          for (final k in keys)
            if (h.aggregateDay(_type, k) > 0) (faNum(int.parse(k.split('/')[2])), h.aggregateDay(_type, k)),
        ];
    }
  }

  /// سری دوم برای نمودار ترکیبی: کالری (برای قدم) یا میانگین متحرک
  List<double> _secondary(HealthProvider h, List<(String, double)> data) {
    if (_type == MetricType.steps) {
      if (_range == 1 || _range == 2) {
        final keys = lastNDayKeys(_range == 1 ? 7 : 30);
        final ks = keys.where((k) => h.aggregateDay(MetricType.steps, k) > 0).toList();
        return [for (final k in ks) h.caloriesOn(k)];
      }
      if (_range == 0) return const [];
      final monthly = <String, double>{};
      for (final m in h.of(MetricType.steps)) {
        final mk = monthKeyOf(m.date);
        monthly[mk] = (monthly[mk] ?? 0) + m.value1;
      }
      final keys = monthly.keys.toList()..sort();
      return [for (final k in keys) calcCalories(steps: monthly[k]!.round(), weightKg: h.currentWeightKg)];
    }
    // میانگین متحرک ۳ نقطه‌ای
    final out = <double>[];
    for (int i = 0; i < data.length; i++) {
      final start = i < 2 ? 0 : i - 2;
      var s = 0.0;
      var c = 0;
      for (int j = start; j <= i; j++) {
        s += data[j].$2;
        c++;
      }
      out.add(c > 0 ? s / c : 0);
    }
    return out;
  }

  // ---------- رسم ----------

  Widget _buildChart(HealthProvider h, List<(String, double)> data, ColorScheme scheme) {
    switch (_chartType) {
      case 0:
        return _line(data, scheme);
      case 1:
        return BarChart(_barData(data, scheme));
      case 2:
        return _pie(h, scheme);
      default:
        return _combo(h, data, scheme);
    }
  }

  double _interval(int n) {
    if (n <= 8) return 1;
    if (n <= 16) return 2;
    if (n <= 31) return 5;
    return (n / 8).ceilToDouble();
  }

  double _maxY(List<(String, double)> data) {
    final m = data.map((d) => d.$2).reduce((a, b) => a > b ? a : b) * 1.15;
    return m <= 0 ? 1 : m;
  }

  FlTitlesData _titles(List<String> labels, ColorScheme scheme) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(faNum(v), style: TextStyle(fontSize: 9, color: scheme.outline)),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: _interval(labels.length),
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(labels[i], style: TextStyle(fontSize: 9, color: scheme.outline)),
            );
          },
        ),
      ),
    );
  }

  Widget _line(List<(String, double)> data, ColorScheme scheme) {
    final def = kMetrics[_type]!;
    final spots = [for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].$2)];
    final maxY = _maxY(data);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: scheme.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles([for (final d in data) d.$1], scheme),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => def.color,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${faDigits(data[s.x.toInt()].$1)}: ${faNum(s.y)} ${def.unit}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Vazirmatn'),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: def.color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: spots.length <= 20,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 3, color: def.color),
            ),
            belowBarData: BarAreaData(show: true, color: def.color.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  BarChartData _barData(List<(String, double)> data, ColorScheme scheme) {
    final def = kMetrics[_type]!;
    return BarChartData(
      minY: 0,
      maxY: _maxY(data),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: scheme.outlineVariant.withOpacity(0.4), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: _titles([for (final d in data) d.$1], scheme),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => def.color,
          getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
            '${faDigits(data[group.x.toInt()].$1)}: ${faNum(rod.toY)} ${def.unit}',
            const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Vazirmatn'),
          ),
        ),
      ),
      barGroups: [
        for (int i = 0; i < data.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].$2,
                width: 14,
                color: def.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _pie(HealthProvider h, ColorScheme scheme) {
    // توزیع بر اساس بازه‌های زمانی روز
    final dates = switch (_range) {
      0 => [jTodayKey()],
      1 => lastNDayKeys(7),
      2 => lastNDayKeys(30),
      _ => lastNDayKeys(365),
    };
    final sums = List.filled(4, 0.0); // صبح ظهر عصر شب
    for (final m in h.entriesInWindow(dates)) {
      if (m.type != _type) continue;
      sums[periodOfTime(m.time) - 1] += m.value1;
    }
    final total = sums.fold(0.0, (a, b) => a + b);
    if (total <= 0) return const EmptyState(icon: Icons.pie_chart_outline, message: 'داده‌ای برای نمایش وجود ندارد');
    final colors = [Colors.amber.shade600, Colors.orange.shade700, Colors.purple.shade400, Colors.indigo.shade400];
    final names = ['صبح', 'ظهر', 'عصر', 'شب'];
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < 4; i++) {
      if (sums[i] <= 0) continue;
      final pct = sums[i] / total * 100;
      sections.add(PieChartSectionData(
        value: sums[i],
        title: '${faNum(pct.round())}٪',
        color: colors[i],
        radius: 60,
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
      ));
    }
    return Column(
      children: [
        Expanded(child: PieChart(PieChartData(sections: sections, sectionsSpace: 3, centerSpaceRadius: 38))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < 4; i++)
              if (sums[i] > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${names[i]}: ${faNum(sums[i])}', style: const TextStyle(fontSize: 11)),
                ]),
          ],
        ),
      ],
    );
  }

  Widget _combo(HealthProvider h, List<(String, double)> data, ColorScheme scheme) {
    final sec = _secondary(h, data);
    if (sec.isEmpty || sec.length != data.length) {
      return BarChart(_barData(data, scheme));
    }
    final secColor = _type == MetricType.steps ? Colors.deepOrange : Theme.of(context).colorScheme.primary;
    final maxY = _maxY(data);
    final maxSec = sec.reduce((a, b) => a > b ? a : b);
    final scaled = [for (final s in sec) maxSec > 0 ? s / maxSec * maxY : 0.0];
    final lineSpots = [for (int i = 0; i < scaled.length; i++) FlSpot(i.toDouble(), scaled[i])];

    return Stack(
      children: [
        BarChart(_barData(data, scheme)),
        IgnorePointer(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: lineSpots,
                  isCurved: true,
                  color: secColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
