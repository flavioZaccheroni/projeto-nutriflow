import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  static Database? _database;
  static String _databaseDirectoryPath = 'nutriflow_data';
  static int _idCounter = 0;
  static final _patientsChanged = StreamController<void>.broadcast();
  static final _mealPlansChanged = StreamController<void>.broadcast();
  static final _historyChanged = StreamController<void>.broadcast();

  static Stream<void> get patientsChanged => _patientsChanged.stream;
  static Stream<void> get mealPlansChanged => _mealPlansChanged.stream;
  static Stream<void> get historyChanged => _historyChanged.stream;

  static String newId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

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
      version: 4,
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
        await _createClinicalTables(db);
        await _createProfessionalTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE patients ADD COLUMN observations TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          await _createClinicalTables(db);
        }
        if (oldVersion < 4) {
          await _createProfessionalTables(db);
        }
      },
    );
  }

  static Future<void> _createClinicalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_records (
        patient_id TEXT PRIMARY KEY,
        sus_number TEXT NOT NULL DEFAULT '',
        insurance TEXT NOT NULL DEFAULT '',
        hospital_record TEXT NOT NULL DEFAULT '',
        clinical_history TEXT NOT NULL DEFAULT '',
        diagnoses TEXT NOT NULL DEFAULT '',
        medications TEXT NOT NULL DEFAULT '',
        allergies TEXT NOT NULL DEFAULT '',
        food_social_history TEXT NOT NULL DEFAULT '',
        lifestyle_habits TEXT NOT NULL DEFAULT '',
        pep_integration_notes TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anthropometric_assessments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        arm_circumference REAL,
        calf_circumference REAL,
        waist_circumference REAL,
        skinfolds TEXT NOT NULL DEFAULT '',
        bioimpedance TEXT NOT NULL DEFAULT '',
        body_composition TEXT NOT NULL DEFAULT '',
        sarcopenia_risk TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lab_results (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        albumin REAL,
        pcr REAL,
        urea REAL,
        creatinine REAL,
        sodium REAL,
        potassium REAL,
        phosphorus REAL,
        hemoglobin REAL,
        glucose REAL,
        hba1c REAL,
        interpretation TEXT NOT NULL DEFAULT '',
        alerts TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_calculations (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        formula TEXT NOT NULL,
        energy_need REAL NOT NULL,
        stress_factor REAL NOT NULL,
        protein_gkg REAL NOT NULL,
        protein_total REAL NOT NULL,
        carbs_g REAL NOT NULL,
        lipids_g REAL NOT NULL,
        meal_distribution TEXT NOT NULL DEFAULT '',
        micronutrients TEXT NOT NULL DEFAULT '',
        clinical_adjustments TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS screening_results (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        protocol TEXT NOT NULL,
        score REAL NOT NULL,
        classification TEXT NOT NULL,
        alerts TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anthropometry_patient ON anthropometric_assessments(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_labs_patient ON lab_results(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nutrition_patient ON nutrition_calculations(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_screening_patient ON screening_results(patient_id)',
    );
  }

  static Future<void> _createProfessionalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diet_prescriptions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        oral_plan TEXT NOT NULL DEFAULT '',
        oral_menu_mode TEXT NOT NULL DEFAULT '',
        enteral_formula TEXT NOT NULL DEFAULT '',
        enteral_volume REAL,
        enteral_hours REAL,
        enteral_speed REAL,
        enteral_density REAL,
        enteral_tolerance TEXT NOT NULL DEFAULT '',
        parenteral_macros TEXT NOT NULL DEFAULT '',
        parenteral_osmolarity REAL,
        parenteral_compatibility TEXT NOT NULL DEFAULT '',
        parenteral_electrolytes TEXT NOT NULL DEFAULT '',
        delivery_notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutritional_evolutions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        model TEXT NOT NULL,
        subjective TEXT NOT NULL DEFAULT '',
        objective TEXT NOT NULL DEFAULT '',
        assessment TEXT NOT NULL DEFAULT '',
        plan TEXT NOT NULL DEFAULT '',
        comparison TEXT NOT NULL DEFAULT '',
        incidents TEXT NOT NULL DEFAULT '',
        multiprofessional_notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS intelligent_alerts (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        drug_nutrient_interactions TEXT NOT NULL DEFAULT '',
        refeeding_risk TEXT NOT NULL DEFAULT '',
        renal_hepatic_restrictions TEXT NOT NULL DEFAULT '',
        electrolyte_alerts TEXT NOT NULL DEFAULT '',
        protein_alert TEXT NOT NULL DEFAULT '',
        generated_alerts TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinical_reports (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        patient_evolution TEXT NOT NULL DEFAULT '',
        plan_adherence TEXT NOT NULL DEFAULT '',
        clinical_results TEXT NOT NULL DEFAULT '',
        quality_indicators TEXT NOT NULL DEFAULT '',
        malnutrition_rate TEXT NOT NULL DEFAULT '',
        intervention_time TEXT NOT NULL DEFAULT '',
        audit_notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_experience_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        digital_plan_status TEXT NOT NULL DEFAULT '',
        substitutions TEXT NOT NULL DEFAULT '',
        reminders TEXT NOT NULL DEFAULT '',
        chat_notes TEXT NOT NULL DEFAULT '',
        web_access_notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS security_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        lgpd_consent TEXT NOT NULL DEFAULT '',
        digital_signature TEXT NOT NULL DEFAULT '',
        access_profile TEXT NOT NULL DEFAULT '',
        backup_status TEXT NOT NULL DEFAULT '',
        audit_log TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS integration_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        hospital_pep TEXT NOT NULL DEFAULT '',
        laboratories TEXT NOT NULL DEFAULT '',
        bioimpedance_devices TEXT NOT NULL DEFAULT '',
        insurance_sus TEXT NOT NULL DEFAULT '',
        finance_schedule TEXT NOT NULL DEFAULT '',
        sync_status TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id)
          REFERENCES patients (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON diet_prescriptions(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_evolutions_patient ON nutritional_evolutions(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alerts_patient ON intelligent_alerts(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reports_patient ON clinical_reports(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_patient_experience_patient ON patient_experience_records(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_security_patient ON security_records(patient_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_integrations_patient ON integration_records(patient_id)',
    );
  }
}
