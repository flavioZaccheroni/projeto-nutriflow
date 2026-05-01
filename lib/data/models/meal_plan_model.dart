class MealPlanModel {
  final String id;
  final String patientId;
  final List<MealModel> meals;
  final DateTime updatedAt;

  const MealPlanModel({
    required this.id,
    required this.patientId,
    required this.meals,
    required this.updatedAt,
  });

  int get foodsCount {
    return meals.fold(0, (total, meal) => total + meal.foods.length);
  }

  MealPlanModel copyWith({
    String? id,
    String? patientId,
    List<MealModel>? meals,
    DateTime? updatedAt,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      meals: meals ?? this.meals,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toDatabase() {
    return {
      'id': id,
      'patient_id': patientId,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MealPlanModel.fromMap(Map<String, dynamic> map) {
    final mealsData = map['meals'] as List? ?? [];

    return MealPlanModel(
      id: map['id'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      meals: mealsData
          .map((meal) => MealModel.fromMap(Map<String, dynamic>.from(meal)))
          .toList(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MealModel {
  final String id;
  final String name;
  final String time;
  final List<FoodItemModel> foods;

  const MealModel({
    required this.id,
    required this.name,
    required this.time,
    required this.foods,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'foods': foods.map((food) => food.toMap()).toList(),
    };
  }

  Map<String, Object?> toDatabase({
    required String mealPlanId,
    required int sortOrder,
  }) {
    return {
      'id': id,
      'meal_plan_id': mealPlanId,
      'name': name,
      'time': time,
      'sort_order': sortOrder,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    final foodsData = map['foods'] as List? ?? [];

    return MealModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      time: map['time'] as String? ?? '',
      foods: foodsData
          .map((food) => FoodItemModel.fromMap(Map<String, dynamic>.from(food)))
          .toList(),
    );
  }
}

class FoodItemModel {
  final String id;
  final String name;
  final String quantity;

  const FoodItemModel({
    required this.id,
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'quantity': quantity};
  }

  Map<String, Object?> toDatabase({
    required String mealId,
    required int sortOrder,
  }) {
    return {
      'id': id,
      'meal_id': mealId,
      'name': name,
      'quantity': quantity,
      'sort_order': sortOrder,
    };
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    return FoodItemModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      quantity: map['quantity'] as String? ?? '',
    );
  }
}
