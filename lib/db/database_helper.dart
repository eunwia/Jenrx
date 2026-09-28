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
      version: 8,
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

    await db.execute('''
      CREATE TABLE bp_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_date TEXT NOT NULL,
        log_time TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date_created TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '1565F5'
      )
    ''');

    await db.execute('''
      CREATE TABLE album_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        date_added TEXT NOT NULL,
        FOREIGN KEY (album_id) REFERENCES albums (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE medicine_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT NOT NULL,
        date_bought TEXT NOT NULL,
        medication_id INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE medications ADD COLUMN icon TEXT DEFAULT 'pill'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE bp_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          log_date TEXT NOT NULL,
          log_time TEXT NOT NULL,
          systolic INTEGER NOT NULL,
          diastolic INTEGER NOT NULL,
          pulse INTEGER
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE bp_logs ADD COLUMN note TEXT");
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE albums (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          date_created TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE album_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          album_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          date_added TEXT NOT NULL,
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE medicine_stock (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit TEXT NOT NULL,
          date_bought TEXT NOT NULL,
          medication_id INTEGER
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute("ALTER TABLE albums ADD COLUMN color TEXT DEFAULT '1565F5'");
    }
  }

  // --- Medications ---

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

  // --- Logs ---

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

  // --- Blood Pressure ---

  Future<int> insertBp(String date, String time, int sys, int dia, int? pulse, String? note) async {
    final db = await database;
    return db.insert('bp_logs', {
      'log_date': date,
      'log_time': time,
      'systolic': sys,
      'diastolic': dia,
      'pulse': pulse,
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getBpForDate(String date) async {
    final db = await database;
    return db.query('bp_logs', where: 'log_date = ?', whereArgs: [date], orderBy: 'log_time DESC');
  }

  Future<List<Map<String, dynamic>>> getRecentBp({int limit = 10}) async {
    final db = await database;
    return db.query('bp_logs', orderBy: 'log_date DESC, log_time DESC', limit: limit);
  }

  Future<void> updateBp(int id, int sys, int dia, int? pulse, String? note) async {
    final db = await database;
    await db.update('bp_logs', {
      'systolic': sys, 'diastolic': dia, 'pulse': pulse, 'note': note,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBp(int id) async {
    final db = await database;
    await db.delete('bp_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Albums (Prescriptions / Lab Results) ---

  Future<int> insertAlbum(String title, String? desc, String date, String color) async {
    final db = await database;
    return db.insert('albums', {'title': title, 'description': desc, 'date_created': date, 'color': color});
  }

  Future<List<Map<String, dynamic>>> getAlbums() async {
    final db = await database;
    return db.query('albums', orderBy: 'date_created DESC');
  }

  Future<void> updateAlbum(int id, String title, String color) async {
    final db = await database;
    await db.update('albums', {'title': title, 'color': color}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAlbum(int id) async {
    final db = await database;
    await db.delete('album_items', where: 'album_id = ?', whereArgs: [id]);
    await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAlbumItem(int albumId, String imagePath, String date) async {
    final db = await database;
    return db.insert('album_items', {'album_id': albumId, 'image_path': imagePath, 'date_added': date});
  }

  Future<List<Map<String, dynamic>>> getAlbumItems(int albumId) async {
    final db = await database;
    return db.query('album_items', where: 'album_id = ?', whereArgs: [albumId], orderBy: 'date_added DESC');
  }

  Future<void> deleteAlbumItem(int id) async {
    final db = await database;
    await db.delete('album_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Medicine Stock ---

  Future<int> insertStock(String name, int qty, String unit, String date, int? medId) async {
    final db = await database;
    return db.insert('medicine_stock', {
      'name': name, 'quantity': qty, 'unit': unit, 'date_bought': date, 'medication_id': medId,
    });
  }

  Future<List<Map<String, dynamic>>> getStock() async {
    final db = await database;
    return db.query('medicine_stock', orderBy: 'date_bought DESC');
  }

  Future<void> updateStockQuantity(int id, int qty) async {
    final db = await database;
    await db.update('medicine_stock', {'quantity': qty}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStock(int id) async {
    final db = await database;
    await db.delete('medicine_stock', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }
}