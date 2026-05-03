import 'dart:async';

import '../../core/database/local_database.dart';
import '../models/history_event_model.dart';

class HistoryRepository {
  Future<List<HistoryEventModel>> findAll() async {
    final db = await LocalDatabase.database;
    final rows = await db.query('history_events', orderBy: 'created_at DESC');
    return rows.map(HistoryEventModel.fromDatabase).toList();
  }

  Stream<List<HistoryEventModel>> watchAll() async* {
    yield await findAll();
    yield* LocalDatabase.historyChanged.asyncMap((_) => findAll());
  }

  Future<void> add({
    String? patientId,
    String? mealPlanId,
    required String type,
    required String description,
  }) async {
    final db = await LocalDatabase.database;
    final event = HistoryEventModel(
      id: LocalDatabase.newId(),
      patientId: patientId,
      mealPlanId: mealPlanId,
      type: type,
      description: description,
      createdAt: DateTime.now(),
    );

    await db.insert('history_events', event.toDatabase());
    LocalDatabase.notifyHistoryChanged();
  }
}
