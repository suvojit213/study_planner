import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/study_session.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'study_planner.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE subjects ADD COLUMN daily_target_minutes INTEGER');
      await db.execute('ALTER TABLE subjects ADD COLUMN monthly_target_minutes INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE subjects_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          daily_target_minutes INTEGER,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO subjects_new (id, name, description, daily_target_minutes, created_at)
        SELECT id, name, description, daily_target_minutes, created_at FROM subjects
      ''');
      await db.execute('DROP TABLE subjects');
      await db.execute('ALTER TABLE subjects_new RENAME TO subjects');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE subjects ADD COLUMN color INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        daily_target_minutes INTEGER,
        created_at INTEGER NOT NULL,
        color INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_minutes INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');
  }

  // Subject operations
  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('subjects');
    return List.generate(maps.length, (i) {
      return Subject.fromMap(maps[i]);
    });
  }

  Future<Subject?> getSubject(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Study session operations
  Future<int> insertStudySession(StudySession session) async {
    final db = await database;
    return await db.insert('study_sessions', session.toMap());
  }

  Future<List<StudySession>> getAllStudySessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('study_sessions');
    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  Future<List<StudySession>> getStudySessionsBySubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  Future<int> updateStudySession(StudySession session) async {
    final db = await database;
    return await db.update(
      'study_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteStudySession(int id) async {
    final db = await database;
    return await db.delete(
      'study_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudySession>> getStudySessionsForSubject(int subjectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'subject_id = ? AND is_completed = 1',
      whereArgs: [subjectId],
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) {
      return StudySession.fromMap(maps[i]);
    });
  }

  Future<double> getAverageSessionDuration(int subjectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(duration_minutes) as avg FROM study_sessions WHERE subject_id = ? AND is_completed = 1',
      [subjectId],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  // Analytics
  Future<int> getTotalStudyTimeForSubject(int subjectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM study_sessions WHERE subject_id = ? AND is_completed = 1',
      [subjectId],
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<Map<String, int>> getTodayStudyTime() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT s.name, SUM(ss.duration_minutes) as total
      FROM study_sessions ss
      JOIN subjects s ON ss.subject_id = s.id
      WHERE ss.start_time >= ? AND ss.start_time < ? AND ss.is_completed = 1
      GROUP BY s.id, s.name
    ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

    Map<String, int> todayTime = {};
    for (var row in result) {
      todayTime[row['name'] as String] = row['total'] as int? ?? 0;
    }
    return todayTime;
  }
}

