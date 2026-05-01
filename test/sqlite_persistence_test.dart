import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriflow_pro/core/database/local_database.dart';
import 'package:nutriflow_pro/data/models/meal_plan_model.dart';
import 'package:nutriflow_pro/data/models/patient_model.dart';
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
}
