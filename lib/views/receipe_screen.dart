import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_app/models/ingredient_model.dart';
import 'package:sample_app/models/recipe_model.dart';
import 'package:sample_app/views/ingredient_selector_screen.dart';

class RecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  RecipeScreen({this.recipe});

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _description, _instructions;
  List<Ingredient> _ingredients = [];
  List<Ingredient> _selectedIngredients = [];
  String? _imageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchIngredientsFromFirebase();
  }

  Future<void> _fetchIngredientsFromFirebase() async {
    QuerySnapshot snapshot = await _firestore.collection('ingredients').get();
    setState(() {
      _ingredients = snapshot.docs.map((doc) => Ingredient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> _uploadImage(String imagePath) async {
    final file = File(imagePath);
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref('recipes/$fileName.jpg').putFile(file);

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _imageUrl = downloadUrl;
        });
        print("Image uploaded successfully: $_imageUrl");
      } else {
        print("Upload failed: ${snapshot.state}");
      }
    } catch (e) {
      print("Error uploading image: ${e.toString()}");
      if (e is FirebaseException) {
        print("Firebase error code: ${e.code}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Recipe Name'),
                initialValue: widget.recipe?.name ?? '',
                onSaved: (value) => _name = value,
                validator: (value) => value!.isEmpty ? 'Enter a recipe name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                initialValue: widget.recipe?.description ?? '',
                onSaved: (value) => _description = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Instructions'),
                initialValue: widget.recipe?.instructions ?? '',
                onSaved: (value) => _instructions = value,
              ),
              Expanded(
                child: _ingredients.isEmpty
                    ? Center(child: Text('No ingredients found'))
                    : ListView.builder(
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = _ingredients[index];
                          return CheckboxListTile(
                            title: Text('${ingredient.name} (${ingredient.quantity})'),
                            value: _selectedIngredients.contains(ingredient),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedIngredients.add(ingredient);
                                } else {
                                  _selectedIngredients.remove(ingredient);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              IconButton(
                icon: Icon(Icons.add_a_photo),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    await _uploadImage(pickedFile.path); // Upload the selected image
                  } else {
                    print("No image selected");
                  }
                },
              ),
              ElevatedButton(
                onPressed: _submitRecipe,
                child: Text('Save Recipe'),
              ),
              if (_imageUrl != null) ...[
                SizedBox(height: 10),
                Image.network(_imageUrl!), // Display uploaded image
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final selectedIngredients = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IngredientsScreen()),
          );

          if (selectedIngredients != null) {
            setState(() {
              _selectedIngredients.addAll(List<Ingredient>.from(selectedIngredients));
            });
          }
        },
      ),
    );
  }

  void _submitRecipe() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Recipe newRecipe = Recipe(
        id: widget.recipe?.id ?? _firestore.collection('recipes').doc().id,
        name: _name!,
        description: _description!,
        instructions: _instructions!,
        ingredients: _selectedIngredients,
        imageUrl: _imageUrl, // Store the image URL in the recipe
      );

      print("Submitting recipe: ${newRecipe.toJson()}");

      _firestore.collection('recipes').doc(newRecipe.id).set(newRecipe.toJson()).then((_) {
        print("Recipe saved successfully");
        Navigator.pop(context, true);
      }).catchError((error) {
        print("Error saving recipe: $error");
        // Optionally show a Snackbar or Toast message here
      });
    } else {
      print("Form validation failed");
    }
  }
}
