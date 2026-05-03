import '../models/food_model.dart';

class FoodRepository {
  static const List<FoodModel> _foods = [
    FoodModel(
      name: 'Alface',
      category: 'Hortalicas',
      portion: '100g',
      calories: 11,
      protein: 1.4,
      carbs: 1.7,
      fat: 0.2,
    ),
    FoodModel(
      name: 'Arroz branco cozido',
      category: 'Cereais',
      portion: '100g',
      calories: 128,
      protein: 2.5,
      carbs: 28.1,
      fat: 0.2,
    ),
    FoodModel(
      name: 'Arroz integral cozido',
      category: 'Cereais',
      portion: '100g',
      calories: 124,
      protein: 2.6,
      carbs: 25.8,
      fat: 1.0,
    ),
    FoodModel(
      name: 'Atum em conserva',
      category: 'Pescados',
      portion: '100g',
      calories: 178,
      protein: 25.7,
      carbs: 0.0,
      fat: 8.0,
    ),
    FoodModel(
      name: 'Aveia em flocos',
      category: 'Cereais',
      portion: '30g',
      calories: 118,
      protein: 4.2,
      carbs: 20.0,
      fat: 2.6,
    ),
    FoodModel(
      name: 'Azeite de oliva',
      category: 'Oleos',
      portion: '10ml',
      calories: 90,
      protein: 0.0,
      carbs: 0.0,
      fat: 10.0,
    ),
    FoodModel(
      name: 'Banana prata',
      category: 'Frutas',
      portion: '100g',
      calories: 98,
      protein: 1.3,
      carbs: 26.0,
      fat: 0.1,
    ),
    FoodModel(
      name: 'Batata doce cozida',
      category: 'Tuberculos',
      portion: '100g',
      calories: 77,
      protein: 0.6,
      carbs: 18.4,
      fat: 0.1,
    ),
    FoodModel(
      name: 'Feijao carioca cozido',
      category: 'Leguminosas',
      portion: '100g',
      calories: 76,
      protein: 4.8,
      carbs: 13.6,
      fat: 0.5,
    ),
    FoodModel(
      name: 'Frango grelhado',
      category: 'Carnes',
      portion: '100g',
      calories: 159,
      protein: 32.0,
      carbs: 0.0,
      fat: 2.5,
    ),
    FoodModel(
      name: 'Ovo cozido',
      category: 'Ovos',
      portion: '1 un',
      calories: 78,
      protein: 6.3,
      carbs: 0.6,
      fat: 5.3,
    ),
    FoodModel(
      name: 'Pao frances',
      category: 'Panificados',
      portion: '50g',
      calories: 150,
      protein: 4.0,
      carbs: 29.3,
      fat: 1.6,
    ),
  ];

  List<FoodModel> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return _foods;
    }

    return _foods.where((food) {
      return food.name.toLowerCase().contains(normalizedQuery) ||
          food.category.toLowerCase().contains(normalizedQuery);
    }).toList();
  }
}
