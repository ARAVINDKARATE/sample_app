import 'ingredient_model.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final List<Ingredient> ingredients;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.ingredients,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'instructions': instructions,
      'ingredients': ingredients.map((ingredient) => ingredient.toJson()).toList(),
      'imageUrl': imageUrl,
    };
  }

  factory Recipe.fromFirestore(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      name: data['name'] as String? ?? '', // Provide a default value
      description: data['description'] as String? ?? '', // Provide a default value
      instructions: data['instructions'] as String? ?? '', // Provide a default value
      ingredients: (data['ingredients'] as List<dynamic>? ?? []).map((item) => Ingredient.fromFirestore(item as Map<String, dynamic>, item['id'])).toList(),
      imageUrl: data['imageUrl'] as String?, // imageUrl can be null
    );
  }
}
