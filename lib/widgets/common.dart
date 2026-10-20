import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/format.dart';

/// الگوی مشترک ویجت‌ها: عنوان بخش، حالت خالی، کارت آمار، چیپ روند

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: c),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: c, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final double? progress;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub!, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
              if (progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// آیکون رنگی داخل دایره ملایم
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge({super.key, required this.icon, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// نمایش مقدار یک اندازه‌گیری به‌همراه واحد
String valueWithUnit(MetricType t, double v1, double? v2) {
  final def = kMetrics[t]!;
  if (def.dual) return '${faNum(v1)}/${faNum(v2 ?? 0)} ${def.unit}';
  return '${faNum(v1)} ${def.unit}';
}

/// متغیر روند (مقایسه با اندازه‌گیری قبلی)
class TrendIcon extends StatelessWidget {
  final double? change; // مثبت/منفی/صفر
  const TrendIcon({super.key, required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == null) return const SizedBox.shrink();
    IconData i;
    Color c;
    if (change! > 0) {
      i = Icons.trending_up;
      c = Colors.orange.shade700;
    } else if (change! < 0) {
      i = Icons.trending_down;
      c = Colors.blue.shade700;
    } else {
      i = Icons.trending_flat;
      c = Colors.grey.shade600;
    }
    return Icon(i, size: 18, color: c);
  }
}
