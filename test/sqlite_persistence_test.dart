import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriflow_pro/core/database/local_database.dart';
import 'package:nutriflow_pro/data/models/meal_plan_model.dart';
import 'package:nutriflow_pro/data/models/patient_model.dart';
import 'package:nutriflow_pro/data/repositories/clinical_repository.dart';
import 'package:nutriflow_pro/data/repositories/history_repository.dart';
import 'package:nutriflow_pro/data/repositories/meal_plan_repository.dart';
import 'package:nutriflow_pro/data/repositories/patient_repository.dart';

void main() {
  late String testDatabaseDirectoryPath;

  setUpAll(() async {
    await LocalDatabase.close();
    testDatabaseDirectoryPath =
        'nutriflow_test_data_${DateTime.now().microsecondsSinceEpoch}';
    final databaseDirectory = Directory(testDatabaseDirectoryPath);
    if (databaseDirectory.existsSync()) {
      databaseDirectory.deleteSync(recursive: true);
    }
    await LocalDatabase.init(databaseDirectoryPath: testDatabaseDirectoryPath);
  });

  tearDownAll(() async {
    await LocalDatabase.close();
    final databaseDirectory = Directory(testDatabaseDirectoryPath);
    if (databaseDirectory.existsSync()) {
      databaseDirectory.deleteSync(recursive: true);
    }
  });

  test('persists patients, meal plans and history in SQLite', () async {
    final patientRepository = PatientRepository();
    final mealPlanRepository = MealPlanRepository();
    final historyRepository = HistoryRepository();

    final patient = await patientRepository.save(
      PatientModel(
        id: '',
        name: 'Ana Souza',
        age: 32,
        weight: 68,
        height: 165,
        goal: 'Emagrecimento',
        observations: 'Prefere treinar pela manha.',
        nextVisit: '10/05/2026',
        createdAt: DateTime(2026, 5),
      ),
    );

    final plan = await mealPlanRepository.save(
      MealPlanModel(
        id: '',
        patientId: patient.id,
        updatedAt: DateTime(2026, 5),
        meals: const [
          MealModel(
            id: 'meal-1',
            name: 'Cafe da manha',
            time: '07:00',
            foods: [
              FoodItemModel(id: 'food-1', name: 'Ovos', quantity: '2 unidades'),
            ],
          ),
        ],
      ),
    );

    final patients = await patientRepository.findAll();
    final savedPlan = await mealPlanRepository.findByPatientId(patient.id);
    final history = await historyRepository.findAll();

    expect(patients, hasLength(1));
    expect(patients.first.name, 'Ana Souza');
    expect(patients.first.age, 32);
    expect(patients.first.goal, 'Emagrecimento');
    expect(patients.first.observations, 'Prefere treinar pela manha.');
    expect(savedPlan, isNotNull);
    expect(savedPlan!.id, plan.id);
    expect(savedPlan.meals.first.foods.first.name, 'Ovos');
    expect(history.map((event) => event.type), contains('patient_created'));
    expect(history.map((event) => event.type), contains('meal_plan_created'));
  });

  test('persists clinical records and automatic screening alerts', () async {
    final patientRepository = PatientRepository();
    final clinicalRepository = ClinicalRepository();

    final patient = await patientRepository.save(
      PatientModel(
        id: '',
        name: 'Carlos Lima',
        age: 58,
        weight: 82,
        height: 172,
        goal: 'Controle glicemico',
        observations: 'Paciente renal em acompanhamento.',
        nextVisit: '12/05/2026',
        createdAt: DateTime(2026, 5),
      ),
    );

    await clinicalRepository.saveClinicalRecord(
      patientId: patient.id,
      data: const {
        'sus_number': '123456789012345',
        'insurance': 'Convenio teste',
        'hospital_record': 'PEP-001',
        'clinical_history': 'Diabetes tipo 2 e DRC.',
        'diagnoses': 'CID-10 E11, N18',
        'medications': 'Metformina',
        'allergies': 'Lactose',
        'food_social_history': 'Baixa ingestao proteica.',
        'lifestyle_habits': 'Sono irregular, sedentario.',
        'pep_integration_notes': 'Aguardando integracao PEP.',
      },
    );

    await clinicalRepository.saveLabs(
      patientId: patient.id,
      data: const {
        'potassium': 5.8,
        'creatinine': 1.6,
        'glucose': 190,
        'interpretation': 'Ajustar conduta renal e glicemica.',
      },
    );

    await clinicalRepository.saveScreening(
      patientId: patient.id,
      data: const {'protocol': 'NRS-2002', 'score': 4},
    );

    final clinical = await clinicalRepository.getClinicalRecord(patient.id);
    final labs = await clinicalRepository.getLatest('lab_results', patient.id);
    final screening = await clinicalRepository.getLatest(
      'screening_results',
      patient.id,
    );

    expect(clinical['sus_number'], '123456789012345');
    expect(labs['alerts'], contains('hipercalemia'));
    expect(labs['alerts'], contains('risco renal'));
    expect(screening['classification'], 'Risco nutricional elevado');
    expect(screening['priority'], 'Alta');
  });

  test('persists professional nutrition workflow records', () async {
    final patientRepository = PatientRepository();
    final clinicalRepository = ClinicalRepository();

    final patient = await patientRepository.save(
      PatientModel(
        id: '',
        name: 'Beatriz Rocha',
        age: 70,
        weight: 54,
        height: 160,
        goal: 'Terapia nutricional hospitalar',
        observations: 'Paciente internada em UTI.',
        nextVisit: '13/05/2026',
        createdAt: DateTime(2026, 5),
      ),
    );

    await clinicalRepository.saveLabs(
      patientId: patient.id,
      data: const {'potassium': 5.9, 'phosphorus': 2.1, 'creatinine': 1.8},
    );
    await clinicalRepository.saveNutritionCalculation(
      patient: patient,
      data: const {'protein_gkg': 0.8, 'stress_factor': 1.2},
    );
    await clinicalRepository.saveDietPrescription(
      patientId: patient.id,
      data: const {
        'oral_plan': 'Dieta oral conforme tolerancia.',
        'enteral_formula': 'Formula polimerica 1.5 kcal/ml',
        'enteral_volume': 1200,
        'enteral_hours': 20,
        'enteral_density': 1.5,
        'parenteral_macros': 'Glicose, aminoacidos e lipidios ajustados.',
      },
    );
    final alerts = await clinicalRepository.saveIntelligentAlerts(
      patient: patient,
      data: const {
        'drug_nutrient_interactions': 'Revisar levotiroxina e dieta enteral.',
        'refeeding_risk': 'alto',
        'renal_hepatic_restrictions': 'renal',
      },
    );
    await clinicalRepository.saveEvolution(
      patientId: patient.id,
      data: const {'model': 'SOAP', 'assessment': 'Melhora parcial.'},
    );
    await clinicalRepository.saveSecurityRecord(
      patientId: patient.id,
      data: const {'lgpd_consent': 'Consentimento registrado.'},
    );
    await clinicalRepository.saveIntegrationRecord(
      patientId: patient.id,
      data: const {'hospital_pep': 'PEP pendente de homologacao.'},
    );

    final prescription = await clinicalRepository.getLatest(
      'diet_prescriptions',
      patient.id,
    );
    final evolution = await clinicalRepository.getLatest(
      'nutritional_evolutions',
      patient.id,
    );
    final security = await clinicalRepository.getLatest(
      'security_records',
      patient.id,
    );
    final integration = await clinicalRepository.getLatest(
      'integration_records',
      patient.id,
    );

    expect(prescription['enteral_speed'], 60);
    expect(alerts, contains('eletrolito critico'));
    expect(alerts, contains('alto risco de realimentacao'));
    expect(alerts, contains('ingestao proteica'));
    expect(evolution['model'], 'SOAP');
    expect(security['lgpd_consent'], 'Consentimento registrado.');
    expect(integration['hospital_pep'], 'PEP pendente de homologacao.');
  });
}
