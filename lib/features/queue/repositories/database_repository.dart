import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:linksync/features/queue/models/sync_task.dart';

class DatabaseRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'linksync.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sync_tasks ADD COLUMN speed REAL DEFAULT 0.0');
        }
      },
    );
  }

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
        speed REAL,
        status INTEGER,
        createdAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE trusted_devices (
        id TEXT PRIMARY KEY,
        name TEXT,
        os TEXT,
        ip TEXT,
        port INTEGER,
        lastSeen TEXT
      )
    ''');
  }

  Future<void> insertTask(SyncTask task) async {
    final db = await database;
    await db.insert('sync_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncTask>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sync_tasks', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => SyncTask.fromMap(maps[i]));
  }

  Future<void> updateTaskProgress(String id, double progress, SyncTaskStatus status, double speed) async {
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
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('sync_tasks', where: 'id = ?', whereArgs: [id]);
  }
}
