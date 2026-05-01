import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriflow_pro/data/models/meal_plan_model.dart';
import 'package:nutriflow_pro/data/models/patient_model.dart';
import 'package:nutriflow_pro/data/services/diet_pdf_report_service.dart';

void main() {
  test('generates a valid diet PDF file', () async {
    final service = DietPdfReportService();
    final patient = PatientModel(
      id: 'patient-1',
      name: 'Ana Souza',
      age: 32,
      weight: 68,
      height: 165,
      goal: 'Emagrecimento',
      observations: 'Evitar lactose no periodo da noite.',
      nextVisit: '10/05/2026',
      createdAt: DateTime(2026, 5),
    );
    final plan = MealPlanModel(
      id: 'plan-1',
      patientId: patient.id,
      updatedAt: DateTime(2026, 5),
      meals: const [
        MealModel(
          id: 'meal-1',
          name: 'Cafe da manha',
          time: '07:00',
          foods: [
            FoodItemModel(id: 'food-1', name: 'Ovos', quantity: '2 unidades'),
            FoodItemModel(id: 'food-2', name: 'Mamao', quantity: '1 fatia'),
          ],
        ),
      ],
    );

    final file = await service.generate(patient: patient, plan: plan);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
      final exportDirectory = Directory('nutriflow_exports');
      if (exportDirectory.existsSync() && exportDirectory.listSync().isEmpty) {
        exportDirectory.deleteSync();
      }
    });

    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
    expect(file.readAsBytesSync().take(4), '%PDF'.codeUnits);
  });
}
