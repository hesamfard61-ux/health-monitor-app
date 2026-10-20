import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/measurement.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../utils/jalali_utils.dart';

/// ساخت و اشتراک‌گذاری خروجی PDF/Excel و پشتیبان JSON
class ExportService {
  static Future<pw.ThemeData> _pdfTheme() async {
    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
    return pw.ThemeData.withFont(base: base, bold: bold);
  }

  static pw.Widget _cell(String t, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        t,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 9,
          color: header ? PdfColors.white : PdfColors.grey900,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<File> exportPdf(List<Measurement> list) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.teal700),
        children: [for (final h in ['ردیف', 'نوع', 'مقدار', 'واحد', 'تاریخ', 'ساعت', 'یادداشت']) _cell(h, header: true)],
      ),
    ];
    int i = 1;
    for (final m in list) {
      final def = kMetrics[m.type]!;
      rows.add(pw.TableRow(children: [
        _cell(faNum(i)),
        _cell(def.label),
        _cell(m.valueText),
        _cell(def.unit),
        _cell(faDigits(m.date)),
        _cell(faDigits(m.time)),
        _cell(m.note.isEmpty ? '-' : m.note),
      ]));
      i++;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('گزارش پایش سلامت', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                'تاریخ تولید: ${faDigits(jTodayKey())}   |   تعداد رکورد: ${faNum(list.length)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: rows,
              ),
            ],
          ),
        ),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<File> exportExcel(List<Measurement> list) async {
    final excel = Excel.createExcel();
    final sheet = excel['گزارش'];
    sheet.appendRow(<CellValue?>[for (final h in ['ردیف', 'نوع', 'مقدار', 'واحد', 'تاریخ', 'ساعت', 'یادداشت']) TextCellValue(h)]);
    int i = 1;
    for (final m in list) {
      final def = kMetrics[m.type]!;
      sheet.appendRow(<CellValue?>[
        IntCellValue(i),
        TextCellValue(def.label),
        DoubleCellValue(m.value1),
        TextCellValue(def.unit),
        TextCellValue(m.date),
        TextCellValue(m.time),
        TextCellValue(m.note),
      ]);
      i++;
    }
    try {
      excel.setDefaultSheet('گزارش');
      excel.delete('Sheet1');
    } catch (_) {}
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes == null) throw Exception('خطا در ساخت فایل اکسل');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> exportBackup(List<Measurement> list) async {
    final data = {
      'app': 'health_monitor',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'measurements': [for (final m in list) m.toMap()],
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/health_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  /// انتخاب و خواندن فایل پشتیبان؛ در صورت انصراف null برمی‌گردد
  static Future<List<Measurement>?> importBackup() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = res?.files.single.path;
    if (path == null) return null;
    final raw = await File(path).readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['measurements'] as List).cast<Map<String, dynamic>>();
    return [for (final m in items) Measurement.fromMap(m)];
  }

  static Future<void> share(File f, String text) async {
    await Share.shareXFiles([XFile(f.path)], text: text);
  }
}
