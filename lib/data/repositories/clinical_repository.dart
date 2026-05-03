import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/local_database.dart';
import '../models/patient_model.dart';
import 'history_repository.dart';

class ClinicalRepository {
  final _historyRepository = HistoryRepository();

  Future<Map<String, Object?>> getClinicalRecord(String patientId) async {
    final db = await LocalDatabase.database;
    final rows = await db.query(
      'clinical_records',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      limit: 1,
    );
    return rows.isEmpty ? {} : rows.first;
  }

  Future<Map<String, Object?>> getLatest(String table, String patientId) async {
    final db = await LocalDatabase.database;
    final rows = await db.query(
      table,
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? {} : rows.first;
  }

  Future<void> saveClinicalRecord({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('clinical_records', {
      'patient_id': patientId,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _historyRepository.add(
      patientId: patientId,
      type: 'clinical_record_updated',
      description: 'Cadastro clinico atualizado.',
    );
    LocalDatabase.notifyHistoryChanged();
  }

  Future<void> saveAnthropometry({
    required PatientModel patient,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final weight = _asDouble(data['weight']) ?? patient.weight;
    final height = _asDouble(data['height']) ?? patient.height;
    final bmi = weight / ((height / 100) * (height / 100));

    await db.insert('anthropometric_assessments', {
      'id': _newId(),
      'patient_id': patient.id,
      ...data,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patient.id,
      type: 'anthropometry_created',
      description: 'Avaliacao antropometrica registrada.',
    );
  }

  Future<void> saveLabs({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final alerts = _labAlerts(data);

    await db.insert('lab_results', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'alerts': alerts,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'lab_results_created',
      description: alerts.isEmpty
          ? 'Exames laboratoriais registrados.'
          : 'Exames registrados com alertas: $alerts',
    );
  }

  Future<void> saveNutritionCalculation({
    required PatientModel patient,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final stressFactor = _asDouble(data['stress_factor']) ?? 1;
    final proteinGkg = _asDouble(data['protein_gkg']) ?? 1.2;
    final energyNeed =
        (_asDouble(data['energy_need']) ?? _mifflin(patient)) * stressFactor;
    final proteinTotal = patient.weight * proteinGkg;
    final carbsG = _asDouble(data['carbs_g']) ?? (energyNeed * 0.5 / 4);
    final lipidsG = _asDouble(data['lipids_g']) ?? (energyNeed * 0.3 / 9);

    await db.insert('nutrition_calculations', {
      'id': _newId(),
      'patient_id': patient.id,
      ...data,
      'formula': data['formula'] ?? 'Mifflin-St Jeor',
      'energy_need': energyNeed,
      'stress_factor': stressFactor,
      'protein_gkg': proteinGkg,
      'protein_total': proteinTotal,
      'carbs_g': carbsG,
      'lipids_g': lipidsG,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patient.id,
      type: 'nutrition_calculation_created',
      description: 'Calculo nutricional registrado.',
    );
  }

  Future<void> saveScreening({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final protocol = data['protocol'] as String? ?? 'NRS-2002';
    final score = _asDouble(data['score']) ?? 0;
    final classification = _screeningClassification(protocol, score);
    final priority = score >= 3 ? 'Alta' : 'Rotina';

    await db.insert('screening_results', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'protocol': protocol,
      'score': score,
      'classification': classification,
      'priority': priority,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'screening_created',
      description: 'Triagem $protocol: $classification.',
    );
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  double _mifflin(PatientModel patient) {
    return (10 * patient.weight) + (6.25 * patient.height) - (5 * patient.age);
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString().replaceAll(',', '.'));
  }

  String _labAlerts(Map<String, Object?> data) {
    final alerts = <String>[];
    final potassium = _asDouble(data['potassium']);
    final creatinine = _asDouble(data['creatinine']);
    final sodium = _asDouble(data['sodium']);
    final phosphorus = _asDouble(data['phosphorus']);
    final glucose = _asDouble(data['glucose']);

    if (potassium != null && potassium >= 5.5) {
      alerts.add('hipercalemia');
    }
    if (creatinine != null && creatinine >= 1.3) {
      alerts.add('risco renal');
    }
    if (sodium != null && (sodium < 135 || sodium > 145)) {
      alerts.add('sodio alterado');
    }
    if (phosphorus != null && phosphorus > 4.5) {
      alerts.add('fosforo elevado');
    }
    if (glucose != null && glucose >= 180) {
      alerts.add('hiperglicemia');
    }

    return alerts.join(', ');
  }

  String _screeningClassification(String protocol, double score) {
    if (protocol == 'GLIM') {
      return score >= 1 ? 'Risco/criterios GLIM presentes' : 'Sem criterio';
    }
    if (score >= 3) {
      return 'Risco nutricional elevado';
    }
    if (score >= 1) {
      return 'Risco nutricional moderado';
    }
    return 'Baixo risco';
  }
}
