import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/models/ingredient_model.dart';

class IngredientsScreen extends StatefulWidget {
  @override
  _IngredientsScreenState createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Ingredient> _ingredients = [];
  List<Ingredient> _selectedIngredients = [];

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  Future<void> _fetchIngredients() async {
    QuerySnapshot snapshot = await _firestore.collection('ingredients').get();
    setState(() {
      _ingredients = snapshot.docs.map((doc) => Ingredient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  void _toggleSelection(Ingredient ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
    });
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String ingredientName = '';
        String ingredientQuantity = '';

        return AlertDialog(
          title: const Text('Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Ingredient Name'),
                onChanged: (value) {
                  ingredientName = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                onChanged: (value) {
                  ingredientQuantity = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (ingredientName.isNotEmpty && ingredientQuantity.isNotEmpty) {
                  _firestore.collection('ingredients').add({
                    'name': ingredientName,
                    'quantity': ingredientQuantity,
                  }).then((value) {
                    // After adding the ingredient, refresh the ingredients list
                    _fetchIngredients();
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    // Handle any errors
                    print("Error adding ingredient: $error");
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addIngredient,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedIngredients);
            },
          ),
        ],
      ),
      body: _ingredients.isEmpty
          ? const Center(child: Text("No Ingredients available"))
          : ListView.builder(
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return ListTile(
                  title: Text(ingredient.name),
                  subtitle: Text(ingredient.quantity.toString()),
                  trailing: Checkbox(
                    value: _selectedIngredients.contains(ingredient),
                    onChanged: (bool? value) {
                      _toggleSelection(ingredient);
                    },
                  ),
                );
              },
            ),
    );
  }
}
