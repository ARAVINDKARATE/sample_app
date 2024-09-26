import 'package:sample_app/models/ingredient_model.dart';

class Recipe {
  String id;
  String name;
  String description;
  String instructions;
  List<Ingredient> ingredients;
  String? imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.ingredients,
    this.imageUrl,
  });

  // Factory constructor to create a Recipe from Firestore document data
  factory Recipe.fromFirestore(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instructions: data['instructions'] ?? '',
      ingredients: (data['ingredients'] as List<dynamic>).map((ingredientData) => Ingredient.fromFirestore(ingredientData as Map<String, dynamic>, '')).toList(),
      imageUrl: data['imageUrl'],
    );
  }

  // Method to convert Recipe instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'instructions': instructions,
      'ingredients': ingredients.map((ingredient) => ingredient.toJson()).toList(),
      'imageUrl': imageUrl,
    };
  }
}
