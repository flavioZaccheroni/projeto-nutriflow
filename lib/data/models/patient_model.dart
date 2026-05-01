class PatientModel {
  final String id;
  final String name;
  final int age;
  final double weight;
  final double height;
  final String goal;
  final String observations;
  final String nextVisit;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.observations,
    required this.nextVisit,
    required this.createdAt,
  });

  double get imc => weight / ((height / 100) * (height / 100));

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? observations,
    String? nextVisit,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      observations: observations ?? this.observations,
      nextVisit: nextVisit ?? this.nextVisit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'observations': observations,
      'nextVisit': nextVisit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> toDatabase() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'observations': observations,
      'next_visit': nextVisit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      goal: map['goal'] as String? ?? '',
      observations: map['observations'] as String? ?? '',
      nextVisit: map['nextVisit'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory PatientModel.fromDatabase(Map<String, Object?> data) {
    return PatientModel(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0,
      height: (data['height'] as num?)?.toDouble() ?? 0,
      goal: data['goal'] as String? ?? '',
      observations: data['observations'] as String? ?? '',
      nextVisit: data['next_visit'] as String? ?? '',
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
