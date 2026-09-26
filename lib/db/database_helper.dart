import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/med_log.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'med_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        times TEXT NOT NULL,
        frequency TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        icon TEXT NOT NULL DEFAULT 'pill'
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        taken_at TEXT,
        log_date TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE medications ADD COLUMN icon TEXT DEFAULT 'pill'");
    }
  }

  Future<int> insertMedication(Medication med) async {
    final db = await database;
    return await db.insert('medications', med.toMap());
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final maps = await db.query('medications', where: 'is_archived = 0');
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<void> archiveMedication(int id) async {
    final db = await database;
    await db.update('medications', {'is_archived': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMedication(Medication med) async {
    final db = await database;
    await db.update('medications', med.toMap(), where: 'id = ?', whereArgs: [med.id]);
  }

  Future<int> insertLog(MedLog log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  Future<void> markTaken(int logId, String takenAt) async {
    final db = await database;
    await db.update('logs', {'taken_at': takenAt},
        where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> undoTaken(int logId) async {
    final db = await database;
    await db.update('logs', {'taken_at': null},
        where: 'id = ?', whereArgs: [logId]);
  }

  Future<List<MedLog>> getLogsForDate(String date) async {
    final db = await database;
    final maps = await db.query('logs', where: 'log_date = ?', whereArgs: [date]);
    return maps.map((m) => MedLog.fromMap(m)).toList();
  }

  String formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> ensureLogsForToday() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = formatDate(today);
    final weekday = today.weekday.toString();

    final meds = await getActiveMedications();
    for (final med in meds) {
      final scheduledToday = med.frequency == 'daily' ||
          med.frequency.split(',').contains(weekday);
      if (!scheduledToday) continue;

      for (final time in med.timeList) {
        final existing = await db.query('logs',
            where: 'medication_id = ? AND scheduled_time = ? AND log_date = ?',
            whereArgs: [med.id, time, todayStr]);
        if (existing.isEmpty) {
          await insertLog(MedLog(
            medicationId: med.id!,
            scheduledTime: time,
            logDate: todayStr,
          ));
        }
      }
    }
  }

  Future<Map<String, String>> getComplianceForMonth(int year, int month) async {
    final db = await database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final end = '$year-${month.toString().padLeft(2, '0')}-31';

    final logs = await db.query('logs',
        where: 'log_date BETWEEN ? AND ?', whereArgs: [start, end]);

    final Map<String, List<bool>> byDate = {};
    for (final row in logs) {
      final date = row['log_date'] as String;
      final taken = row['taken_at'] != null;
      byDate.putIfAbsent(date, () => []).add(taken);
    }

    return byDate.map((date, list) {
      final allTaken = list.every((t) => t);
      final noneTaken = list.every((t) => !t);
      return MapEntry(date, allTaken ? 'green' : (noneTaken ? 'red' : 'yellow'));
    });
  }
}