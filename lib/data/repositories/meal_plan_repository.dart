import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/local_database.dart';
import '../models/meal_plan_model.dart';
import 'history_repository.dart';

class MealPlanRepository {
  final _historyRepository = HistoryRepository();

  Future<List<MealPlanModel>> findAll() async {
    final db = await LocalDatabase.database;
    final rows = await db.query('meal_plans', orderBy: 'updated_at DESC');
    final plans = <MealPlanModel>[];

    for (final row in rows) {
      plans.add(await _hydratePlan(db, row));
    }

    return plans;
  }

  Future<MealPlanModel?> findByPatientId(String patientId) async {
    final db = await LocalDatabase.database;
    final rows = await db.query(
      'meal_plans',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _hydratePlan(db, rows.first);
  }

  Stream<List<MealPlanModel>> watchAll() async* {
    yield await findAll();
    yield* LocalDatabase.mealPlansChanged.asyncMap((_) => findAll());
  }

  Future<MealPlanModel> save(MealPlanModel plan) async {
    final db = await LocalDatabase.database;
    final isNew = plan.id.isEmpty;
    final id = isNew ? LocalDatabase.newId() : plan.id;
    final savedPlan = plan.copyWith(id: id, updatedAt: DateTime.now());

    await db.transaction((transaction) async {
      await transaction.insert(
        'meal_plans',
        savedPlan.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.delete(
        'meals',
        where: 'meal_plan_id = ?',
        whereArgs: [savedPlan.id],
      );

      for (var mealIndex = 0; mealIndex < savedPlan.meals.length; mealIndex++) {
        final meal = savedPlan.meals[mealIndex];
        await transaction.insert(
          'meals',
          meal.toDatabase(mealPlanId: savedPlan.id, sortOrder: mealIndex),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (var foodIndex = 0; foodIndex < meal.foods.length; foodIndex++) {
          final food = meal.foods[foodIndex];
          await transaction.insert(
            'food_items',
            food.toDatabase(mealId: meal.id, sortOrder: foodIndex),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    await _historyRepository.add(
      patientId: savedPlan.patientId,
      mealPlanId: savedPlan.id,
      type: isNew ? 'meal_plan_created' : 'meal_plan_updated',
      description: isNew
          ? 'Plano alimentar criado.'
          : 'Plano alimentar atualizado.',
    );
    LocalDatabase.notifyMealPlansChanged();
    return savedPlan;
  }

  Future<MealPlanModel> _hydratePlan(
    DatabaseExecutor db,
    Map<String, Object?> planRow,
  ) async {
    final mealRows = await db.query(
      'meals',
      where: 'meal_plan_id = ?',
      whereArgs: [planRow['id']],
      orderBy: 'sort_order ASC',
    );
    final meals = <MealModel>[];

    for (final mealRow in mealRows) {
      final foodRows = await db.query(
        'food_items',
        where: 'meal_id = ?',
        whereArgs: [mealRow['id']],
        orderBy: 'sort_order ASC',
      );

      meals.add(
        MealModel(
          id: mealRow['id'] as String? ?? '',
          name: mealRow['name'] as String? ?? '',
          time: mealRow['time'] as String? ?? '',
          foods: foodRows
              .map(
                (foodRow) => FoodItemModel(
                  id: foodRow['id'] as String? ?? '',
                  name: foodRow['name'] as String? ?? '',
                  quantity: foodRow['quantity'] as String? ?? '',
                ),
              )
              .toList(),
        ),
      );
    }

    return MealPlanModel(
      id: planRow['id'] as String? ?? '',
      patientId: planRow['patient_id'] as String? ?? '',
      meals: meals,
      updatedAt:
          DateTime.tryParse(planRow['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
