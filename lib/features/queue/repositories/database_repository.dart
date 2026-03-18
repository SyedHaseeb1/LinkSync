import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/foundation.dart';
import 'package:linksync/features/queue/models/sync_task.dart';

class DatabaseRepository {
  static Database? _database;
  static final Lock _lock = Lock();

  // ✅ Thread-safe DB getter
  Future<Database> get database async {
    if (_database != null) return _database!;

    return await _lock.synchronized(() async {
      if (_database != null) return _database!;
      _database = await _initDB();
      return _database!;
    });
  }

  // ✅ Initialize DB
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'linksync.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ✅ Create tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_tasks (
        id TEXT PRIMARY KEY,
        type INTEGER,
        sourceDeviceId TEXT,
        targetDeviceId TEXT,
        targetDeviceName TEXT,
        filePath TEXT,
        fileSize INTEGER,
        progress REAL,
        speed REAL DEFAULT 0.0,
        status INTEGER,
        createdAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE trusted_devices (
        id TEXT PRIMARY KEY,
        name TEXT,
        os TEXT,
        ip TEXT,
        port INTEGER,
        lastSeen INTEGER
      )
    ''');

    // ✅ Index for performance
    await db.execute(
      'CREATE INDEX idx_sync_tasks_createdAt ON sync_tasks(createdAt DESC)',
    );
  }

  // ✅ Migration
  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE sync_tasks ADD COLUMN speed REAL DEFAULT 0.0',
      );
    }
  }

  // ✅ Insert task
  Future<void> insertTask(SyncTask task) async {
    try {
      final db = await database;
      await db.insert(
        'sync_tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('DB insert error: $e');
    }
  }

  // ✅ Get all tasks
  Future<List<SyncTask>> getAllTasks() async {
    try {
      final db = await database;
      final maps = await db.query(
        'sync_tasks',
        orderBy: 'createdAt DESC',
      );

      return List.generate(
        maps.length,
            (i) => SyncTask.fromMap(maps[i]),
      );
    } catch (e) {
      debugPrint('DB fetch error: $e');
      return [];
    }
  }

  // ✅ Update progress
  Future<void> updateTaskProgress(
      String id,
      double progress,
      SyncTaskStatus status,
      double speed,
      ) async {
    try {
      final db = await database;

      await db.update(
        'sync_tasks',
        {
          'progress': progress,
          'status': status.index,
          'speed': speed,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('DB update error: $e');
    }
  }

  // ✅ Delete task
  Future<void> deleteTask(String id) async {
    try {
      final db = await database;
      await db.delete(
        'sync_tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('DB delete error: $e');
    }
  }

  // ✅ Clear all tasks (optional)
  Future<void> clearTasks() async {
    try {
      final db = await database;
      await db.delete('sync_tasks');
    } catch (e) {
      debugPrint('DB clear error: $e');
    }
  }

  // ✅ Close DB (IMPORTANT for desktop)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}