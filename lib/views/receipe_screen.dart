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

  Future<void> _uploadImage(XFile pickedFile) async {
    final file = File(pickedFile.path);
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('files/$fileName.jpg');

    try {
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
      });
      print("Image uploaded successfully: $_imageUrl");
    } catch (e) {
      print("Error uploading image: $e");
    }
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
        imageUrl: _imageUrl,
      );

      print("Submitting recipe: ${newRecipe.toJson()}");

      _firestore.collection('recipes').doc(newRecipe.id).set(newRecipe.toJson()).then((_) {
        print("Recipe saved successfully");
        Navigator.pop(context, true);
      }).catchError((error) {
        print("Error saving recipe: $error");
      });
    } else {
      print("Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: 'Recipe Name',
                initialValue: widget.recipe?.name ?? '',
                onSaved: (value) => _name = value,
              ),
              SizedBox(height: 20),
              _buildTextField(
                label: 'Description',
                initialValue: widget.recipe?.description ?? '',
                onSaved: (value) => _description = value,
              ),
              SizedBox(height: 20),
              _buildTextField(
                label: 'Instructions',
                initialValue: widget.recipe?.instructions ?? '',
                onSaved: (value) => _instructions = value,
              ),
              _ingredients.isEmpty
                  ? Center(child: Text('No ingredients found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              ingredient.imageUrl != null
                                  ? Image.network(
                                      ingredient.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(width: 50, height: 50), // Placeholder if no image
                              SizedBox(width: 10),
                              Text('${ingredient.name} (${ingredient.quantity})'),
                            ],
                          ),
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
              IconButton(
                icon: Icon(Icons.add_a_photo),
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    await _uploadImage(pickedFile);
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
                Image.network(_imageUrl!),
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

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
