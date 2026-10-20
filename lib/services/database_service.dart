import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/measurement.dart';

/// پایگاه داده محلی SQLite
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    return openDatabase(
      p.join(dir.path, 'health_monitor.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            value1 REAL NOT NULL,
            value2 REAL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            note TEXT DEFAULT '',
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<List<Measurement>> getAll() async {
    final db = await database;
    final rows = await db.query('measurements', orderBy: 'date DESC, time DESC, id DESC');
    return [for (final r in rows) Measurement.fromMap(r)];
  }

  Future<int> insert(Measurement m) async {
    final db = await database;
    final map = m.toMap()..remove('id');
    map['createdAt'] = DateTime.now().toIso8601String();
    return db.insert('measurements', map);
  }

  Future<int> update(Measurement m) async {
    final db = await database;
    final map = m.toMap()..remove('id');
    return db.update('measurements', map, where: 'id = ?', whereArgs: [m.id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  /// جایگزینی کامل داده‌ها (بازیابی از پشتیبان)
  Future<void> replaceAll(List<Measurement> list) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('measurements');
      for (final m in list) {
        final map = m.toMap()..remove('id');
        map['createdAt'] = DateTime.now().toIso8601String();
        await txn.insert('measurements', map);
      }
    });
  }
}
