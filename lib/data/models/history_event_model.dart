class HistoryEventModel {
  final String id;
  final String? patientId;
  final String? mealPlanId;
  final String type;
  final String description;
  final DateTime createdAt;

  const HistoryEventModel({
    required this.id,
    required this.patientId,
    required this.mealPlanId,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  Map<String, Object?> toDatabase() {
    return {
      'id': id,
      'patient_id': patientId,
      'meal_plan_id': mealPlanId,
      'type': type,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryEventModel.fromDatabase(Map<String, Object?> data) {
    return HistoryEventModel(
      id: data['id'] as String? ?? '',
      patientId: data['patient_id'] as String?,
      mealPlanId: data['meal_plan_id'] as String?,
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
