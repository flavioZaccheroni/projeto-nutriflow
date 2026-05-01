import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/cloud/supabase_service.dart';
import '../../core/database/local_database.dart';

class CloudSyncResult {
  final int pushedPatients;
  final int pushedMealPlans;
  final int pushedHistory;
  final int pulledPatients;
  final int pulledMealPlans;
  final int pulledHistory;

  const CloudSyncResult({
    required this.pushedPatients,
    required this.pushedMealPlans,
    required this.pushedHistory,
    required this.pulledPatients,
    required this.pulledMealPlans,
    required this.pulledHistory,
  });

  int get total =>
      pushedPatients +
      pushedMealPlans +
      pushedHistory +
      pulledPatients +
      pulledMealPlans +
      pulledHistory;
}

class CloudSyncService {
  bool get canSync {
    return SupabaseService.isConfigured &&
        SupabaseService.client.auth.currentUser != null;
  }

  Future<CloudSyncResult> syncAll() async {
    if (!canSync) {
      return const CloudSyncResult(
        pushedPatients: 0,
        pushedMealPlans: 0,
        pushedHistory: 0,
        pulledPatients: 0,
        pulledMealPlans: 0,
        pulledHistory: 0,
      );
    }

    final pushedPatients = await _pushPatients();
    final pushedMealPlans = await _pushMealPlans();
    final pushedHistory = await _pushHistory();
    final pulledPatients = await _pullPatients();
    final pulledMealPlans = await _pullMealPlans();
    final pulledHistory = await _pullHistory();

    LocalDatabase.notifyPatientsChanged();
    LocalDatabase.notifyMealPlansChanged();
    LocalDatabase.notifyHistoryChanged();

    return CloudSyncResult(
      pushedPatients: pushedPatients,
      pushedMealPlans: pushedMealPlans,
      pushedHistory: pushedHistory,
      pulledPatients: pulledPatients,
      pulledMealPlans: pulledMealPlans,
      pulledHistory: pulledHistory,
    );
  }

  Future<int> _pushPatients() async {
    final db = await LocalDatabase.database;
    final rows = await db.query('patients');
    if (rows.isEmpty) {
      return 0;
    }

    final userId = SupabaseService.client.auth.currentUser!.id;
    await SupabaseService.client
        .from('patients')
        .upsert(
          rows.map((row) => {...row, 'user_id': userId}).toList(),
          onConflict: 'id',
        );
    return rows.length;
  }

  Future<int> _pushMealPlans() async {
    final db = await LocalDatabase.database;
    final plans = await db.query('meal_plans');
    final meals = await db.query('meals');
    final foods = await db.query('food_items');
    final userId = SupabaseService.client.auth.currentUser!.id;

    if (plans.isNotEmpty) {
      await SupabaseService.client
          .from('meal_plans')
          .upsert(
            plans.map((row) => {...row, 'user_id': userId}).toList(),
            onConflict: 'id',
          );
    }
    if (meals.isNotEmpty) {
      await SupabaseService.client
          .from('meals')
          .upsert(
            meals.map((row) => {...row, 'user_id': userId}).toList(),
            onConflict: 'id',
          );
    }
    if (foods.isNotEmpty) {
      await SupabaseService.client
          .from('food_items')
          .upsert(
            foods.map((row) => {...row, 'user_id': userId}).toList(),
            onConflict: 'id',
          );
    }

    return plans.length;
  }

  Future<int> _pushHistory() async {
    final db = await LocalDatabase.database;
    final rows = await db.query('history_events');
    if (rows.isEmpty) {
      return 0;
    }

    final userId = SupabaseService.client.auth.currentUser!.id;
    await SupabaseService.client
        .from('history_events')
        .upsert(
          rows.map((row) => {...row, 'user_id': userId}).toList(),
          onConflict: 'id',
        );
    return rows.length;
  }

  Future<int> _pullPatients() async {
    final db = await LocalDatabase.database;
    final rows = await SupabaseService.client
        .from('patients')
        .select()
        .order('created_at');

    await db.transaction((transaction) async {
      for (final row in rows) {
        await transaction.insert(
          'patients',
          _withoutUserId(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return rows.length;
  }

  Future<int> _pullMealPlans() async {
    final db = await LocalDatabase.database;
    final plans = await SupabaseService.client
        .from('meal_plans')
        .select()
        .order('updated_at');
    final meals = await SupabaseService.client
        .from('meals')
        .select()
        .order('sort_order');
    final foods = await SupabaseService.client
        .from('food_items')
        .select()
        .order('sort_order');

    await db.transaction((transaction) async {
      for (final row in plans) {
        await transaction.insert(
          'meal_plans',
          _withoutUserId(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in meals) {
        await transaction.insert(
          'meals',
          _withoutUserId(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in foods) {
        await transaction.insert(
          'food_items',
          _withoutUserId(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return plans.length;
  }

  Future<int> _pullHistory() async {
    final db = await LocalDatabase.database;
    final rows = await SupabaseService.client
        .from('history_events')
        .select()
        .order('created_at');

    await db.transaction((transaction) async {
      for (final row in rows) {
        await transaction.insert(
          'history_events',
          _withoutUserId(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return rows.length;
  }

  Map<String, Object?> _withoutUserId(Map<String, dynamic> row) {
    final data = Map<String, Object?>.from(row);
    data.remove('user_id');
    return data;
  }
}
