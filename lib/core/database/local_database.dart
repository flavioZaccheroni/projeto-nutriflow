import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  static Database? _database;
  static String _databaseDirectoryPath = 'nutriflow_data';
  static final _patientsChanged = StreamController<void>.broadcast();
  static final _mealPlansChanged = StreamController<void>.broadcast();
  static final _historyChanged = StreamController<void>.broadcast();

  static Stream<void> get patientsChanged => _patientsChanged.stream;
  static Stream<void> get mealPlansChanged => _mealPlansChanged.stream;
  static Stream<void> get historyChanged => _historyChanged.stream;

  static Future<void> init({
    String databaseDirectoryPath = 'nutriflow_data',
  }) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _databaseDirectoryPath = databaseDirectoryPath;
    _database = await _openDatabase();
  }

  static Future<Database> get database async {
    return _database ??= await _openDatabase();
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  static void notifyPatientsChanged() {
    _patientsChanged.add(null);
    _mealPlansChanged.add(null);
    _historyChanged.add(null);
  }

  static void notifyMealPlansChanged() {
    _mealPlansChanged.add(null);
    _historyChanged.add(null);
  }

  static void notifyHistoryChanged() {
    _historyChanged.add(null);
  }

  static Future<Database> _openDatabase() async {
    final directory = Directory(_databaseDirectoryPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final databasePath = path.join(directory.path, 'nutriflow.db');

    return openDatabase(
      databasePath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            weight REAL NOT NULL,
            height REAL NOT NULL,
            goal TEXT NOT NULL,
            observations TEXT NOT NULL DEFAULT '',
            next_visit TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE meal_plans (
            id TEXT PRIMARY KEY,
            patient_id TEXT NOT NULL UNIQUE,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (patient_id)
              REFERENCES patients (id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE meals (
            id TEXT PRIMARY KEY,
            meal_plan_id TEXT NOT NULL,
            name TEXT NOT NULL,
            time TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            FOREIGN KEY (meal_plan_id)
              REFERENCES meal_plans (id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE food_items (
            id TEXT PRIMARY KEY,
            meal_id TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            FOREIGN KEY (meal_id)
              REFERENCES meals (id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE history_events (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            meal_plan_id TEXT,
            type TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (patient_id)
              REFERENCES patients (id)
              ON DELETE SET NULL,
            FOREIGN KEY (meal_plan_id)
              REFERENCES meal_plans (id)
              ON DELETE SET NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_meal_plans_patient_id ON meal_plans(patient_id)',
        );
        await db.execute(
          'CREATE INDEX idx_meals_plan_id ON meals(meal_plan_id)',
        );
        await db.execute(
          'CREATE INDEX idx_food_items_meal_id ON food_items(meal_id)',
        );
        await db.execute(
          'CREATE INDEX idx_history_patient_id ON history_events(patient_id)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE patients ADD COLUMN observations TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }
}
