import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_app/models/ingredient_model.dart';

class IngredientsScreen extends StatefulWidget {
  @override
  _IngredientsScreenState createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Ingredient> _ingredients = [];
  List<Ingredient> _selectedIngredients = [];
  List<Ingredient> _filteredIngredients = [];
  TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _ingredientImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchIngredients();

    _searchController.addListener(() {
      _filterIngredients();
    });
  }

  Future<void> _fetchIngredients() async {
    QuerySnapshot snapshot = await _firestore.collection('ingredients').get();
    setState(() {
      _ingredients = snapshot.docs.map((doc) => Ingredient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
      _filteredIngredients = _ingredients;
    });
  }

  void _filterIngredients() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIngredients = _ingredients.where((ingredient) {
        return ingredient.name.toLowerCase().contains(query);
      }).toList();
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

  Future<void> _addIngredient() async {
    String ingredientName = '';
    String ingredientQuantity = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
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
              // Image upload button
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    // Upload the image and get the URL (you should implement the upload logic)
                    // Here, we just set the local path for the sake of preview
                    setState(() {
                      _ingredientImageUrl = pickedFile.path; // Store the local path for preview
                    });
                  }
                },
                child: const Text('Upload Image'),
              ),
              // Display uploaded image preview
              if (_ingredientImageUrl != null) Image.file(File(_ingredientImageUrl!), height: 100, fit: BoxFit.cover),
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
                  // Here, you would upload the image to Firebase Storage and get the download URL
                  // For now, we'll just add the ingredient without an image URL
                  _firestore.collection('ingredients').add({
                    'name': ingredientName,
                    'quantity': ingredientQuantity,
                    'imageUrl': _ingredientImageUrl, // Store the image URL if available
                  }).then((value) {
                    _fetchIngredients();
                    Navigator.of(context).pop();
                  }).catchError((error) {
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

  void _deleteIngredient(String ingredientId) {
    _firestore.collection('ingredients').doc(ingredientId).delete().then((_) {
      // After deleting, fetch the updated ingredient list
      _fetchIngredients();
    }).catchError((error) {
      print("Error deleting ingredient: $error");
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Ingredients',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredIngredients.isEmpty
                ? const Center(child: Text("No Ingredients available"))
                : ListView.builder(
                    itemCount: _filteredIngredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _filteredIngredients[index];
                      return ListTile(
                        title: Text(ingredient.name),
                        subtitle: Text(ingredient.quantity.toString()),
                        leading: ingredient.imageUrl != null ? Image.network(ingredient.imageUrl!, width: 50, height: 50, fit: BoxFit.cover) : null, // Display the image if available
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedIngredients.contains(ingredient),
                              onChanged: (bool? value) {
                                _toggleSelection(ingredient);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteIngredient(ingredient.id); // Call delete method
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
