import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String id;
  final String name;
  final String quantity;
  final String? imageUrl;

  Ingredient({required this.id, required this.name, required this.quantity, this.imageUrl});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory Ingredient.fromFirestore(Map<String, dynamic> data, String id) {
    return Ingredient(
      id: id,
      name: data['name'],
      quantity: data['quantity'],
      imageUrl: data['imageUrl'],
    );
  }
}
