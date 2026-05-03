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

  Future<void> saveDietPrescription({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final volume = _asDouble(data['enteral_volume']);
    final hours = _asDouble(data['enteral_hours']);
    final density = _asDouble(data['enteral_density']);
    final speed = volume != null && hours != null && hours > 0
        ? volume / hours
        : null;

    await db.insert('diet_prescriptions', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'enteral_speed': speed,
      'enteral_density': density,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'diet_prescription_created',
      description: 'Prescricao dietetica oral, enteral e parenteral salva.',
    );
  }

  Future<void> saveEvolution({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('nutritional_evolutions', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'model': data['model'] ?? 'SOAP',
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'nutritional_evolution_created',
      description: 'Evolucao nutricional registrada.',
    );
  }

  Future<String> saveIntelligentAlerts({
    required PatientModel patient,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    final latestLabs = await getLatest('lab_results', patient.id);
    final latestNutrition = await getLatest(
      'nutrition_calculations',
      patient.id,
    );
    final generated = _intelligentAlerts(
      patient,
      data,
      latestLabs,
      latestNutrition,
    );

    await db.insert('intelligent_alerts', {
      'id': _newId(),
      'patient_id': patient.id,
      ...data,
      'generated_alerts': generated,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patient.id,
      type: 'intelligent_alerts_created',
      description: generated.isEmpty
          ? 'Alertas clinicos revisados sem alerta automatico.'
          : 'Alertas clinicos gerados: $generated',
    );
    return generated;
  }

  Future<void> saveClinicalReport({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('clinical_reports', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'clinical_report_created',
      description: 'Relatorio e indicadores registrados.',
    );
  }

  Future<void> savePatientExperience({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('patient_experience_records', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'patient_experience_created',
      description: 'Experiencia digital do paciente registrada.',
    );
  }

  Future<void> saveSecurityRecord({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('security_records', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'security_record_created',
      description: 'Registro de seguranca, LGPD e auditoria salvo.',
    );
  }

  Future<void> saveIntegrationRecord({
    required String patientId,
    required Map<String, Object?> data,
  }) async {
    final db = await LocalDatabase.database;
    await db.insert('integration_records', {
      'id': _newId(),
      'patient_id': patientId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _historyRepository.add(
      patientId: patientId,
      type: 'integration_record_created',
      description: 'Mapa de integracoes registrado.',
    );
  }

  String _newId() => LocalDatabase.newId();

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

  String _intelligentAlerts(
    PatientModel patient,
    Map<String, Object?> data,
    Map<String, Object?> labs,
    Map<String, Object?> nutrition,
  ) {
    final alerts = <String>[];
    final potassium = _asDouble(labs['potassium']);
    final phosphorus = _asDouble(labs['phosphorus']);
    final glucose = _asDouble(labs['glucose']);
    final creatinine = _asDouble(labs['creatinine']);
    final proteinGkg = _asDouble(nutrition['protein_gkg']);
    final manualRestrictions = data['renal_hepatic_restrictions']
        ?.toString()
        .toLowerCase();
    final refeedingRisk = data['refeeding_risk']?.toString().toLowerCase();
    final interactions = data['drug_nutrient_interactions']?.toString();

    if (potassium != null && potassium >= 5.5) {
      alerts.add('eletrolito critico: potassio elevado');
    }
    if (phosphorus != null && phosphorus < 2.5) {
      alerts.add('risco de sindrome de realimentacao por fosforo baixo');
    }
    if (glucose != null && glucose >= 180) {
      alerts.add('glicemia elevada');
    }
    if (creatinine != null && creatinine >= 1.3) {
      alerts.add('avaliar restricao renal automatica');
    }
    if (proteinGkg != null && proteinGkg < 1) {
      alerts.add('ingestao proteica possivelmente inadequada');
    }
    if ((manualRestrictions ?? '').contains('renal')) {
      alerts.add('restricao renal registrada');
    }
    if ((refeedingRisk ?? '').contains('alto')) {
      alerts.add('alto risco de realimentacao');
    }
    if ((interactions ?? '').trim().isNotEmpty) {
      alerts.add('revisar interacao farmaco-nutriente');
    }

    return alerts.toSet().join(', ');
  }
}
