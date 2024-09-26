class Ingredient {
  String id;
  String name;
  String quantity;
  final String? imageUrl;

  Ingredient({required this.id, required this.name, required this.quantity, this.imageUrl});

  // Factory constructor to create an Ingredient from Firestore document data
  factory Ingredient.fromFirestore(Map<String, dynamic> data, String id) {
    return Ingredient(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  // Method to convert Ingredient instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
    };
  }
}
