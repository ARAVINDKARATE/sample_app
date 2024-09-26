class Ingredient {
  String id;
  String name;
  String quantity;

  Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
  });

  // Factory constructor to create an Ingredient from Firestore document data
  factory Ingredient.fromFirestore(Map<String, dynamic> data, String id) {
    return Ingredient(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? '',
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
